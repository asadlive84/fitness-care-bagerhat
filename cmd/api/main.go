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
	memberSvc     := services.NewMemberService(memberRepo)
	planSvc       := services.NewPlanService(planRepo)
	subSvc        := services.NewSubscriptionService(subRepo, memberRepo, planRepo)
	paymentSvc    := services.NewPaymentService(paymentPgRepo, memberRepo)
	weightLogSvc  := services.NewWeightLogService(weightLogRepo)
	workoutLogSvc := services.NewWorkoutLogService(workoutLogRepo)
	dietLogSvc    := services.NewDietLogService(dietLogRepo)
	msgRepo        := postgres.NewMessageRepo(db)
	messageSvc     := services.NewMessageService(msgRepo)
	notifRepo      := postgres.NewNotificationRepo(db)
	fcmTokenRepo   := postgres.NewFCMTokenRepo(db)
	settingSvc     := services.NewSettingService(settingRepo)

	// ── Handlers ──────────────────────────────────────────────────────────────
	authHandler          := handlers.NewAuthHandler(authSvc, log)
	adminMemberHandler   := handlers.NewAdminMemberHandler(memberSvc, log)
	adminPlanHandler     := handlers.NewAdminPlanHandler(planSvc, log)
	adminSubHandler      := handlers.NewAdminSubscriptionHandler(subSvc, log)
	adminPaymentHandler  := handlers.NewAdminPaymentHandler(paymentSvc, log)
	memberHandler          := handlers.NewMemberHandler(memberSvc, subSvc, paymentSvc, weightLogSvc, workoutLogSvc, dietLogSvc, log)
	adminMsgHandler        := handlers.NewAdminMessageHandler(messageSvc, log)
	memberMsgHandler       := handlers.NewMemberMessageHandler(messageSvc, log)
	adminSettingsHandler   := handlers.NewAdminSettingsHandler(settingSvc, log)
	memberNotifHandler     := handlers.NewMemberNotificationHandler(fcmTokenRepo, settingRepo, log)

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
	app.Use(middleware.RequestID())
	app.Use(middleware.RequestLogger(log))

	// ── Swagger UI ───────────────────────────────────────────────────────────
	app.Get("/swagger/*", fiberSwagger.HandlerDefault)

	// ── Health ───────────────────────────────────────────────────────────────
	app.Get("/healthz", server.Healthz)
	app.Get("/readyz", server.ReadyzHandler(db, redisClient))

	// ── API v1 ────────────────────────────────────────────────────────────────
	v1 := app.Group("/api/v1")

	// Auth — rate-limited to 10 req/min per IP to slow brute-force attempts.
	authRateLimit := fiberlimiter.New(fiberlimiter.Config{
		Max:        10,
		Expiration: time.Minute,
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

	auth := v1.Group("/auth", authRateLimit)
	auth.Post("/admin/login", authHandler.AdminLogin)
	auth.Post("/member/login", authHandler.MemberLogin)
	auth.Post("/refresh", authHandler.RefreshToken)
	auth.Post("/change-password",
		middleware.RequireAuth(jwtManager),
		middleware.RequireRole(appauth.RoleMember),
		authHandler.ChangePassword,
	)

	// Admin sub-router — all routes require admin JWT.
	admin := v1.Group("/admin",
		middleware.RequireAuth(jwtManager),
		middleware.RequireRole(appauth.RoleAdmin),
	)

	// Admin — member management (Step 5)
	admin.Post("/members",                        adminMemberHandler.CreateMember)
	admin.Get("/members",                         adminMemberHandler.ListMembers)
	admin.Get("/members/:id",                     adminMemberHandler.GetMember)
	admin.Patch("/members/:id",                   adminMemberHandler.UpdateMember)
	admin.Patch("/members/:id/status",            adminMemberHandler.UpdateMemberStatus)
	admin.Post("/members/:id/password/reset",     adminMemberHandler.ResetMemberPassword)
	admin.Delete("/members/:id",                  adminMemberHandler.DeleteMember)

	// Admin — plans (Step 6)
	admin.Post("/plans",        adminPlanHandler.CreatePlan)
	admin.Get("/plans",         adminPlanHandler.ListPlans)
	admin.Patch("/plans/:id",   adminPlanHandler.UpdatePlan)
	admin.Delete("/plans/:id",  adminPlanHandler.DeletePlan)

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
