//	@title			Fitness Care Bagerhat API
//	@version		1.0.0
//	@description	Production-grade REST API for a single-gym management system in Bagerhat, Bangladesh. Two roles: Admin (gym owner) and Member (gym customer).
//	@host			localhost:8080
//	@BasePath		/
//	@schemes		http https
//
//	@securityDefinitions.apikey	BearerAuth
//	@in							header
//	@name						Authorization
//	@description				Enter the token with the Bearer prefix: "Bearer {token}"
package main

import (
	"context"
	"log/slog"
	"os"
	"os/signal"
	"syscall"
	"time"
	_ "time/tzdata" // embed timezone database so time.LoadLocation works in scratch containers

	appauth "github.com/asadlive84/fitness-care-bagerhat/internal/auth"
	"github.com/asadlive84/fitness-care-bagerhat/internal/cache"
	"github.com/asadlive84/fitness-care-bagerhat/internal/config"
	"github.com/asadlive84/fitness-care-bagerhat/internal/database"
	"github.com/asadlive84/fitness-care-bagerhat/internal/handlers"
	applogger "github.com/asadlive84/fitness-care-bagerhat/internal/logger"
	"github.com/asadlive84/fitness-care-bagerhat/internal/middleware"
	_ "github.com/asadlive84/fitness-care-bagerhat/docs"
	"github.com/asadlive84/fitness-care-bagerhat/internal/notifier"
	"github.com/asadlive84/fitness-care-bagerhat/internal/repositories/cached"
	"github.com/asadlive84/fitness-care-bagerhat/internal/repositories/postgres"
	"github.com/asadlive84/fitness-care-bagerhat/internal/scheduler"
	"github.com/asadlive84/fitness-care-bagerhat/internal/server"
	"github.com/asadlive84/fitness-care-bagerhat/internal/services"
	"github.com/gofiber/fiber/v2"
	fibercors    "github.com/gofiber/fiber/v2/middleware/cors"
	fiberlimiter "github.com/gofiber/fiber/v2/middleware/limiter"
	fiberrecover "github.com/gofiber/fiber/v2/middleware/recover"
	fiberSwagger "github.com/gofiber/swagger"
)

func main() {
	// ── Config ────────────────────────────────────────────────────────────────
	cfg, err := config.Load()
	if err != nil {
		slog.Error("load config", "error", err)
		os.Exit(1)
	}

	// ── File Uploads ──────────────────────────────────────────────────────────
	if err := os.MkdirAll(cfg.Upload.Dir, 0755); err != nil {
		slog.Error("create upload directory", "error", err, "dir", cfg.Upload.Dir)
		os.Exit(1)
	}

	// ── Database ──────────────────────────────────────────────────────────────
	db, err := database.Open(cfg.Database)
	if err != nil {
		slog.Error("open database", "error", err)
		os.Exit(1)
	}
	defer db.Close()

	// ── DB async log sink ─────────────────────────────────────────────────────
	dbSink := applogger.NewDBSink(db)
	defer dbSink.Close()

	// ── Logger ────────────────────────────────────────────────────────────────
	log := applogger.New(cfg, dbSink)
	slog.SetDefault(log)

	log.Info("starting fitness-care-bagerhat API",
		slog.String("env", cfg.App.Env),
		slog.String("port", cfg.App.Port),
	)

	// ── Redis ─────────────────────────────────────────────────────────────────
	redisClient, err := cache.New(cfg.Redis)
	if err != nil {
		log.Error("connect redis", "error", err)
		os.Exit(1)
	}
	defer redisClient.Close()

	// ── Repositories ──────────────────────────────────────────────────────────
	adminPgRepo     := postgres.NewAdminRepo(db)
	memberPgRepo    := postgres.NewMemberRepo(db)
	planPgRepo      := postgres.NewPlanRepo(db)
	subPgRepo       := postgres.NewSubscriptionRepo(db)
	settingPgRepo   := postgres.NewSettingRepo(db)
	paymentPgRepo   := postgres.NewPaymentRepo(db)
	weightLogRepo   := postgres.NewWeightLogRepo(db)
	workoutLogRepo  := postgres.NewWorkoutLogRepo(db)
	dietLogRepo     := postgres.NewDietLogRepo(db)
	expensePgRepo   := postgres.NewExpenseRepo(db)
	financialPgRepo := postgres.NewFinancialRepo(db)

	memberRepo := cached.NewMemberRepo(memberPgRepo, redisClient, log)
	planRepo := cached.NewPlanRepo(planPgRepo, redisClient, log)
	subRepo := cached.NewSubscriptionRepo(subPgRepo, redisClient, log)
	settingRepo := cached.NewSettingRepo(settingPgRepo, redisClient, log)

	// Silence "declared and not used" until later steps consume these.
	_ = planRepo
	_ = subRepo
	_ = settingRepo

	// ── JWT ───────────────────────────────────────────────────────────────────
	jwtManager := appauth.NewManager(cfg.JWT)

	// ── Services ──────────────────────────────────────────────────────────────
	authSvc       := services.NewAuthService(memberRepo, adminPgRepo, jwtManager)
	memberSvc     := services.NewMemberService(memberRepo, weightLogRepo)
	planSvc       := services.NewPlanService(planRepo)
	settingSvc     := services.NewSettingService(settingRepo)
	subSvc        := services.NewSubscriptionService(subRepo, memberRepo, planRepo, settingSvc)
	paymentSvc    := services.NewPaymentService(paymentPgRepo, memberRepo)
	weightLogSvc  := services.NewWeightLogService(weightLogRepo, memberRepo)
	expenseSvc    := services.NewExpenseService(expensePgRepo, cfg.App.Timezone)
	financialSvc  := services.NewFinancialsService(financialPgRepo, cfg.App.Timezone)
	workoutLogSvc := services.NewWorkoutLogService(workoutLogRepo)
	dietLogSvc    := services.NewDietLogService(dietLogRepo)
	msgRepo        := postgres.NewMessageRepo(db)
	messageSvc     := services.NewMessageService(msgRepo, memberRepo)
	notifRepo      := postgres.NewNotificationRepo(db)
	fcmTokenRepo   := postgres.NewFCMTokenRepo(db)
	aiRepo         := postgres.NewAIRepo(db)
	aiSvc          := services.NewAIService(aiRepo, cfg.AI, log)

	// Seed default AI prompts for the first time
	if err := aiSvc.SeedDefaultPrompts(context.Background()); err != nil {
		log.Error("Failed to seed default AI prompts on startup", "error", err)
	}

	// ── Handlers ──────────────────────────────────────────────────────────────
	authHandler          := handlers.NewAuthHandlerWithMemberSvc(authSvc, memberSvc, log)
	adminMemberHandler   := handlers.NewAdminMemberHandler(memberSvc, subSvc, aiRepo, aiSvc, log)
	adminPlanHandler     := handlers.NewAdminPlanHandler(planSvc, log)
	adminSubHandler      := handlers.NewAdminSubscriptionHandler(subSvc, log)
	adminPaymentHandler  := handlers.NewAdminPaymentHandler(paymentSvc, log)
	adminExpenseHandler  := handlers.NewAdminExpenseHandler(expenseSvc, log)
	adminFinancialsHandler := handlers.NewAdminFinancialsHandler(financialSvc, log)
	memberHandler          := handlers.NewMemberHandler(memberSvc, subSvc, paymentSvc, weightLogSvc, workoutLogSvc, dietLogSvc, log)
	adminMsgHandler        := handlers.NewAdminMessageHandler(messageSvc, log)
	memberMsgHandler       := handlers.NewMemberMessageHandler(messageSvc, log)
	adminSettingsHandler   := handlers.NewAdminSettingsHandler(settingSvc, log)
	memberNotifHandler     := handlers.NewMemberNotificationHandler(fcmTokenRepo, settingRepo, log)
	uploadHandler          := handlers.NewUploadHandler(cfg.Upload, log)
	aiHandler              := handlers.NewAIHandler(aiSvc, aiRepo, memberRepo, log)
	superAdminHandler      := handlers.NewSuperAdminHandler(memberRepo, adminPgRepo, log)
	superAdminAuditHandler := handlers.NewSuperAdminAuditHandler(aiRepo, log)

	// ── Notifier (FCM or noop) ────────────────────────────────────────────────
	var push notifier.Notifier
	if cfg.FCM.ProjectID != "" && cfg.FCM.CredentialsJSON != "" {
		fcmN, err := notifier.NewFCMNotifier(context.Background(), cfg.FCM.ProjectID, cfg.FCM.CredentialsJSON, log)
		if err != nil {
			log.Warn("FCM init failed — using noop notifier", "error", err)
			push = notifier.NewNoopNotifier(log)
		} else {
			push = fcmN
			log.Info("FCM notifier enabled", "project_id", cfg.FCM.ProjectID)
		}
	} else {
		log.Info("FCM credentials not configured — using noop notifier")
		push = notifier.NewNoopNotifier(log)
	}

	// ── Scheduler ─────────────────────────────────────────────────────────────
	tz, err := time.LoadLocation(cfg.App.Timezone)
	if err != nil {
		log.Warn("unknown timezone, falling back to UTC", "tz", cfg.App.Timezone)
		tz = time.UTC
	}
	sched := scheduler.New(tz, settingSvc, memberRepo, subRepo, weightLogRepo, notifRepo, fcmTokenRepo, push, log)
	sched.Start()
	defer sched.Stop()

	// ── Fiber ─────────────────────────────────────────────────────────────────
	app := fiber.New(fiber.Config{
		ReadTimeout:  cfg.App.ReadTimeout,
		WriteTimeout: cfg.App.WriteTimeout,
		ErrorHandler: func(c *fiber.Ctx, err error) error {
			code := fiber.StatusInternalServerError
			if e, ok := err.(*fiber.Error); ok {
				code = e.Code
			}
			log.ErrorContext(c.UserContext(), "unhandled error",
				slog.String("error", err.Error()),
				slog.String("path", c.Path()),
			)
			return c.Status(code).JSON(fiber.Map{
				"success": false,
				"error":   fiber.Map{"code": "INTERNAL_ERROR", "message": err.Error()},
			})
		},
	})

	// ── Global middleware ─────────────────────────────────────────────────────
	app.Use(fiberrecover.New())

	// CORS — must be before auth so pre-flight OPTIONS requests pass through.
	{
		filtered := make([]string, 0)
		for _, o := range cfg.CORS.AllowedOrigins {
			if o != "" && o != "*" {
				filtered = append(filtered, o)
			}
		}
		if len(filtered) == 0 {
			filtered = []string{
				"http://localhost:3000",
				"http://localhost:5050",
				"http://localhost:5173",
				"http://10.0.2.2:3000",
			}
		}
		app.Use(fibercors.New(fibercors.Config{
			AllowOrigins: joinOrigins(filtered),
			AllowMethods: "GET,POST,PUT,PATCH,DELETE,OPTIONS",
			AllowHeaders: "Origin,Content-Type,Accept,Authorization,X-Request-ID",
			ExposeHeaders: "X-Request-ID",
			MaxAge:        86400,
		}))
	}

	app.Use(middleware.RequestID())
	app.Use(middleware.RequestLogger(log))

	// ── Swagger UI ───────────────────────────────────────────────────────────
	app.Get("/swagger/*", fiberSwagger.HandlerDefault)

	// ── Health ───────────────────────────────────────────────────────────────
	app.Get("/healthz", server.Healthz)
	app.Get("/readyz", server.ReadyzHandler(db, redisClient))

	// ── Static Files ──────────────────────────────────────────────────────────
	app.Static("/uploads", cfg.Upload.Dir)

	// ── Rate limiters ────────────────────────────────────────────────────────
	rateLimited := func(max int, window time.Duration) fiber.Handler {
		return fiberlimiter.New(fiberlimiter.Config{
			Max:        max,
			Expiration: window,
			LimitReached: func(c *fiber.Ctx) error {
				return c.Status(fiber.StatusTooManyRequests).JSON(fiber.Map{
					"success": false,
					"error": fiber.Map{
						"code":    "RATE_LIMITED",
						"message": "Too many requests, please try again later",
					},
				})
			},
		})
	}

	// ── API v1 ────────────────────────────────────────────────────────────────
	// Global: 300 req/min per IP — broad DoS protection across all API routes.
	v1 := app.Group("/api/v1", rateLimited(300, time.Minute))

	// Upload — 20 uploads/hour per IP to prevent storage abuse.
	v1.Post("/upload", rateLimited(20, time.Hour), middleware.RequireAuth(jwtManager), uploadHandler.HandleUpload)

	// AI — 30 req/min per IP (AI calls are expensive).
	aiGroup := v1.Group("/ai",
		rateLimited(30, time.Minute),
		middleware.RequireAuth(jwtManager),
		middleware.RequireAIPermission(aiRepo, memberPgRepo, log),
	)
	aiGroup.Patch("/profile", aiHandler.SetupAIProfile)
	aiGroup.Post("/diet-chart", aiHandler.GenerateDietChart)
	aiGroup.Post("/food-log", middleware.RequireDailyFoodLimit(aiRepo, log), aiHandler.AnalyzeFoodImage)
	aiGroup.Get("/food-logs", aiHandler.GetFoodLogs)

	// Auth — 10 req/min for login/refresh, 5 req/hour for registration.
	authRateLimit    := rateLimited(10, time.Minute)
	registerLimit    := rateLimited(5, time.Hour)

	// Public plans (no auth) — used by landing page
	v1.Get("/plans", adminPlanHandler.PublicListPlans)

	auth := v1.Group("/auth")
	auth.Post("/admin/login",  authRateLimit, authHandler.AdminLogin)
	auth.Post("/member/login", authRateLimit, authHandler.MemberLogin)
	auth.Post("/refresh",      authRateLimit, authHandler.RefreshToken)
	auth.Post("/register",     registerLimit, authHandler.RegisterMember)
	auth.Post("/change-password",
		authRateLimit,
		middleware.RequireAuth(jwtManager),
		middleware.RequireRole(appauth.RoleMember),
		authHandler.ChangePassword,
	)

	// Admin sub-router — admin and superadmin JWTs are accepted.
	admin := v1.Group("/admin",
		middleware.RequireAuth(jwtManager),
		middleware.RequireAdminOrSuperAdmin(),
	)

	// Admin — member management (Step 5)
	admin.Post("/members",                        adminMemberHandler.CreateMember)
	admin.Get("/members",                         adminMemberHandler.ListMembers)
	admin.Get("/members/:id",                     adminMemberHandler.GetMember)
	admin.Patch("/members/:id",                   adminMemberHandler.UpdateMember)
	admin.Patch("/members/:id/status",            adminMemberHandler.UpdateMemberStatus)
	admin.Post("/members/:id/password/reset",     adminMemberHandler.ResetMemberPassword)
	admin.Delete("/members/:id",                  adminMemberHandler.DeleteMember)
	admin.Patch("/members/:id/ai",                 adminMemberHandler.UpdateMemberAI)
	admin.Post("/members/:id/approve",             adminMemberHandler.ApproveMember)
	admin.Post("/members/:id/reject",              adminMemberHandler.RejectMember)
	admin.Post("/members/:id/diet-chart",          adminMemberHandler.GenerateMemberDietChart)
	admin.Post("/members/:id/diet-chart/approve",  adminMemberHandler.ApproveMemberDietChart)
	admin.Post("/members/:id/diet-chart/decline",  adminMemberHandler.DeclineMemberDietChart)
	admin.Patch("/members/:id/profile-picture",    adminMemberHandler.UpdateMemberProfilePicture)

	// Admin — plans (Step 6)
	admin.Post("/plans",                   adminPlanHandler.CreatePlan)
	admin.Get("/plans",                    adminPlanHandler.ListPlans)
	admin.Patch("/plans/:id",              adminPlanHandler.UpdatePlan)
	admin.Patch("/plans/:id/visibility",   adminPlanHandler.SetPlanVisibility)
	admin.Delete("/plans/:id",             adminPlanHandler.DeletePlan)

	// Admin — subscriptions (Step 6)
	admin.Post("/members/:id/subscriptions",          adminSubHandler.AssignPlan)
	admin.Get("/members/:id/subscriptions",           adminSubHandler.ListSubscriptions)
	admin.Patch("/members/:id/subscriptions/active",  adminSubHandler.UpdateActive)

	// Admin — settings (Step 10)
	admin.Get("/settings",   adminSettingsHandler.GetSettings)
	admin.Patch("/settings", adminSettingsHandler.UpdateSetting)

	// Admin — messages (Step 9)
	admin.Post("/messages/broadcast",                    adminMsgHandler.SendBroadcast)
	admin.Post("/messages/direct",                       adminMsgHandler.SendDirect)
	admin.Get("/messages/conversations",                 adminMsgHandler.ListConversations)
	admin.Get("/messages/conversations/:member_id",      adminMsgHandler.GetConversation)

	// Admin — payments (Step 7)
	// NOTE: /payments/summary must be registered before /members/:id/payments
	// so Fiber doesn't confuse "summary" with a member ID.
	admin.Get("/payments/summary",          adminPaymentHandler.GetPaymentSummary)
	admin.Post("/payments",                 adminPaymentHandler.RecordPayment)
	admin.Get("/members/:id/payments",      adminPaymentHandler.ListMemberPayments)

	// Admin — operational expenses & financials
	admin.Post("/expenses",            adminExpenseHandler.RecordExpense)
	admin.Get("/expenses",             adminExpenseHandler.ListExpenses)
	admin.Get("/expenses/summary",     adminExpenseHandler.GetExpensesSummary)
	admin.Get("/financials/calendar",  adminExpenseHandler.GetDailyFinancials)
	admin.Get("/financials/report",    adminFinancialsHandler.GetFinancialsReport)

	// Member self-service sub-router (Step 8)
	member := v1.Group("/member",
		middleware.RequireAuth(jwtManager),
		middleware.RequireRole(appauth.RoleMember),
	)
	member.Get("/profile",      memberHandler.GetProfile)
	member.Patch("/profile",    memberHandler.UpdateProfile)
	member.Get("/subscription", memberHandler.GetActiveSubscription)
	member.Get("/payments",     memberHandler.GetPayments)

	member.Post("/weight-logs", memberHandler.LogWeight)
	member.Get("/weight-logs",  memberHandler.ListWeightLogs)
	member.Post("/workout-logs", memberHandler.LogWorkout)
	member.Get("/workout-logs",  memberHandler.ListWorkoutLogs)
	member.Post("/diet-logs",   memberHandler.LogDiet)
	member.Get("/diet-logs",    memberHandler.ListDietLogs)

	// Member — messages (Step 9)
	member.Get("/messages",     memberMsgHandler.GetMessages)
	member.Post("/messages",    memberMsgHandler.SendMessage)

	// Member — notification preferences (Step 10)
	member.Post("/fcm-token",             memberNotifHandler.RegisterFCMToken)
	member.Patch("/notifications/mute",   memberNotifHandler.MuteNotifications)

	// SuperAdmin sub-router — superadmin JWT only.
	superadmin := v1.Group("/superadmin",
		middleware.RequireAuth(jwtManager),
		middleware.RequireSuperAdmin(),
	)
	superadmin.Get("/stats",  superAdminHandler.Stats)
	superadmin.Get("/admins", superAdminHandler.ListAdmins)

	// SuperAdmin — global AI audit + cost endpoints
	superadmin.Get("/audit/ai",              superAdminAuditHandler.ListAIAudit)
	superadmin.Get("/audit/ai/cost-by-gym",  superAdminAuditHandler.AICostByGym)
	superadmin.Get("/audit/ai/heavy-users",  superAdminAuditHandler.AIHeavyUsers)

	// Machine-to-machine admin creation endpoint secured via X-API-KEY environment configuration
	v1.Post("/sa/admins",
		middleware.RequireAPIKey(cfg.SuperAdmin.ApiKey),
		superAdminHandler.CreateAdmin,
	)

	// ── Superadmin startup seed ───────────────────────────────────────────────
	seedSuperAdmin(context.Background(), adminPgRepo, cfg, log)

	// ── Graceful shutdown ─────────────────────────────────────────────────────
	quit := make(chan os.Signal, 1)
	signal.Notify(quit, syscall.SIGINT, syscall.SIGTERM)

	go func() {
		if err := app.Listen(cfg.App.Port); err != nil {
			log.Error("http server error", "error", err)
			os.Exit(1)
		}
	}()

	log.Info("server listening", slog.String("port", cfg.App.Port))
	<-quit
	log.Info("shutdown signal received")

	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()
	if err := app.ShutdownWithContext(ctx); err != nil {
		log.Error("graceful shutdown failed", "error", err)
	}
	log.Info("server stopped")
}

// joinOrigins joins a slice of allowed origins into a comma-separated string
// as required by the Fiber CORS middleware.
func joinOrigins(origins []string) string {
	result := ""
	for i, o := range origins {
		if i > 0 {
			result += ","
		}
		result += o
	}
	return result
}
