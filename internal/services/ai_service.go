package services

import (
	"context"
	"encoding/json"
	"fmt"
	"log/slog"
	"strings"
	"time"

	"github.com/asadlive84/fitness-care-bagerhat/internal/config"
	sqlcdb "github.com/asadlive84/fitness-care-bagerhat/internal/database/sqlc"
	"github.com/asadlive84/fitness-care-bagerhat/internal/models"
	"github.com/asadlive84/fitness-care-bagerhat/internal/repositories/postgres"
	"github.com/google/uuid"
	"google.golang.org/genai"
)

type AIService struct {
	repo *postgres.AIRepo
	cfg  config.AIConfig
	log  *slog.Logger
}

func NewAIService(repo *postgres.AIRepo, cfg config.AIConfig, log *slog.Logger) *AIService {
	return &AIService{
		repo: repo,
		cfg:  cfg,
		log:  log.With(slog.String("component", "ai_service")),
	}
}

// SeedDefaultPrompts always upserts the global default prompts so prompt
// changes in code are applied on the next server restart.
func (s *AIService) SeedDefaultPrompts(ctx context.Context) error {
	defaultPrompts := map[string]string{
		"diet_generation_prompt": `Act as an expert Clinical Nutritionist and Fitness Coach. Your task is to generate a highly detailed, personalized diet chart based on the customer's personal profile (Name, Gender, Age, Weight), goals, specific GYM TIME, and a STRICT Max Daily Budget.

Every single food item must be fully organic/natural (strictly NO processed food). The final output MUST be strictly in JSON format with no additional conversational text or markdown formatting outside the JSON block.

Key Requirements:
1. STRICT BUDGET LIMIT: You are provided with a "Max Daily Budget". The sum of all item prices (total_cost) MUST be strictly less than or equal to this limit. You must creatively adjust food quantities or select cheaper organic alternatives to ensure the budget is NEVER exceeded.
2. Dynamic Calorie Calculation: Use the provided Age, Gender, and Weight to estimate the optimal daily target calories and macros for the user's specific goal.
3. Pricing in English: All price fields must be written in English numbers and text (e.g., "15 BDT", "40-50 BDT").
4. Dynamic Meal Timing: Adjust the ideal_time for the "Pre-Workout" (1-1.5 hours before gym) and "Post-Workout" (within 45 mins after gym) meals based on the provided "Gym Time". Adjust the rest of the day's meals around this schedule.
5. Item Details & Preparation: Explicitly break down what each food is made of and step-by-step instructions on how to prepare it safely.
6. Bottom Totals: Include total_calories and total_cost at the very end of the JSON object as simple integers.

Use the exact JSON structure below:
{
  "customer_profile": {
    "name": "Customer Name",
    "gender": "Gender",
    "age": 0,
    "weight_kg": 0
  },
  "target_summary": "A personalized summary addressing the customer by name, explaining their calorie targets, gym time, and how the diet fits strictly within their budget limit.",
  "daily_targets": {
    "target_calories": 0,
    "protein_g": 0,
    "carbs_g": 0,
    "fat_g": 0
  },
  "detailed_diet_chart": [
    {
      "meal_name": "Name of the meal",
      "ideal_time": "Suggested time range",
      "estimated_meal_cost_range_bdt": "e.g., 50-60 BDT",
      "foods": [
        {
          "item_name": "Name of the food item",
          "quantity": "Amount/Serving size",
          "estimated_price": "Single item price in English (e.g., 20 BDT)",
          "price_range": "Price range in English (e.g., 15-25 BDT)",
          "ingredients_and_nature": "What it is made of and its organic source details",
          "preparation_steps": "Detailed step-by-step instructions",
          "nutritional_benefit": "Why this is included for the customer's goal"
        }
      ],
      "estimated_meal_calories": 0
    }
  ],
  "overall_budget_and_hydration_tips": [
    "Tip 1 regarding grocery shopping within budget",
    "Tip 2 regarding hydration"
  ],
  "total_calories": 0,
  "total_cost": 0
}

Do not add any markdown blocks or extra explanation; output ONLY valid raw JSON.`,
		"food_validation_prompt": `Analyze this image and return a JSON containing calories, protein, carbs, and fats.`,
	}

	for pType, pText := range defaultPrompts {
		s.log.Info("Upserting default AI prompt", "type", pType)
		_ = s.repo.UpdateAIPromptGlobal(ctx, pType, pText, true)
	}

	// Seed default model names — only if not already set.
	defaultModels := map[string]string{
		"ai_text_model":   "gemini-3.1-flash-lite",
		"ai_vision_model": "gemini-3.1-flash-lite",
	}
	for key, model := range defaultModels {
		_, err := s.repo.GetSystemSetting(ctx, key, nil)
		if err != nil {
			s.log.Info("Seeding default AI model setting", "key", key, "model", model)
			_ = s.repo.UpdateSystemSetting(ctx, key, model, nil)
		}
	}

	return nil
}

// DietChartOptions holds the runtime inputs for diet chart generation.
type DietChartOptions struct {
	Language     string // "en" | "bn" — text language for the output
	GymTime      string // e.g. "6:00 PM to 7:30 PM"
	Location     string // e.g. "Bagerhat"
	MaxBudgetBDT string // e.g. "200"
}

// GenerateDietChart calls Gemini to generate a personalized diet chart.
func (s *AIService) GenerateDietChart(ctx context.Context, member *models.Member, opts DietChartOptions) (json.RawMessage, int, error) {
	promptData, err := s.repo.GetAIPrompt(ctx, "diet_generation_prompt", member.CreatedByAdminID)
	if err != nil {
		// Inline fallback matches the seeded prompt exactly
		promptData = sqlcdb.AiPrompt{PromptText: "Act as an expert Clinical Nutritionist and Fitness Coach. Generate a personalized daily diet chart in strict JSON format with no markdown. Output only valid raw JSON."}
	}

	goalVal := "Muscle Gain & Fitness"
	if member.Goal != nil && *member.Goal != "" {
		goalVal = *member.Goal
	}
	weightVal := "Not set"
	if member.CurrentWeight != nil {
		weightVal = fmt.Sprintf("%.1f kg", *member.CurrentWeight)
	}
	heightVal := "Not set"
	if member.HeightCm != nil {
		heightVal = fmt.Sprintf("%.1f cm", *member.HeightCm)
	}
	ageVal := "Not set"
	if member.DateOfBirth != nil {
		years := time.Now().Year() - member.DateOfBirth.Year()
		if time.Now().YearDay() < member.DateOfBirth.YearDay() {
			years--
		}
		ageVal = fmt.Sprintf("%d", years)
	}
	hobbiesVal := "None"
	if len(member.Hobbies) > 0 {
		hobbiesVal = strings.Join(member.Hobbies, ", ")
	}
	gymTimeVal := opts.GymTime
	if gymTimeVal == "" {
		gymTimeVal = "6:00 PM to 7:30 PM"
	}
	locationVal := opts.Location
	if locationVal == "" {
		locationVal = "Bagerhat, Bangladesh"
	}
	maxBudgetVal := opts.MaxBudgetBDT
	if maxBudgetVal == "" {
		budgetMap := map[string]string{"Low": "150", "Medium": "300", "High": "500"}
		if member.BudgetLevel != nil {
			if mapped, ok := budgetMap[*member.BudgetLevel]; ok {
				maxBudgetVal = mapped
			}
		}
		if maxBudgetVal == "" {
			maxBudgetVal = "200"
		}
	}

	userData := fmt.Sprintf(
		"- Customer Name: %s\n- Gender: %s\n- Age: %s\n- Weight: %s\n- Height: %s\n- User Goal: %s\n- Physical Activities/Hobbies: %s\n- Current Location: %s\n- Max Daily Budget: %s BDT\n- Gym Time: %s\n- Language of Text Fields inside JSON: Bengali (বাংলা), BUT all price values must be in English.",
		member.Name, member.Gender, ageVal, weightVal, heightVal, goalVal, hobbiesVal, locationVal, maxBudgetVal, gymTimeVal,
	)

	client, err := genai.NewClient(ctx, &genai.ClientConfig{
		APIKey:  s.cfg.TextAPIKey,
		Backend: genai.BackendGeminiAPI,
	})
	if err != nil {
		return nil, 0, fmt.Errorf("create gemini client: %w", err)
	}

	modelName := s.getTextModel(ctx, member.CreatedByAdminID)

	result, err := client.Models.GenerateContent(
		ctx,
		modelName,
		genai.Text(promptData.PromptText+"\n\nInput Context to process:\n"+userData),
		&genai.GenerateContentConfig{
			ResponseMIMEType: "application/json",
		},
	)
	if err != nil {
		return nil, 0, fmt.Errorf("generate diet chart: %w", err)
	}

	responseJSON := result.Text()

	var totalTokens int
	if result.UsageMetadata != nil {
		totalTokens = int(result.UsageMetadata.TotalTokenCount)
	}

	// Strip any accidental markdown fences
	responseJSON = strings.TrimPrefix(responseJSON, "```json")
	responseJSON = strings.TrimPrefix(responseJSON, "```")
	responseJSON = strings.TrimSuffix(responseJSON, "```")
	responseJSON = strings.TrimSpace(responseJSON)

	return json.RawMessage(responseJSON), totalTokens, nil
}

// GenerateNutritionFromImage calls Gemini to analyze a food image.
func (s *AIService) GenerateNutritionFromImage(ctx context.Context, member *models.Member, imageBytes []byte, mimeType string) (json.RawMessage, int, error) {
	promptData, err := s.repo.GetAIPrompt(ctx, "food_validation_prompt", member.CreatedByAdminID)
	if err != nil {
		promptData = sqlcdb.AiPrompt{
			PromptText: "Analyze this image and return a JSON containing calories, protein, carbs, and fats.",
		}
	}

	goalValVision := "Not set"
	if member.Goal != nil {
		goalValVision = *member.Goal
	}
	weightValVision := "Not set"
	if member.CurrentWeight != nil {
		weightValVision = fmt.Sprintf("%.1f kg", *member.CurrentWeight)
	}

	userData := fmt.Sprintf("Weight: %s, Goal: %s", weightValVision, goalValVision)

	client, err := genai.NewClient(ctx, &genai.ClientConfig{
		APIKey:  s.cfg.VisionAPIKey,
		Backend: genai.BackendGeminiAPI,
	})
	if err != nil {
		return nil, 0, fmt.Errorf("create gemini client: %w", err)
	}

	modelName := s.getVisionModel(ctx, member.CreatedByAdminID)

	content := genai.NewContentFromParts([]*genai.Part{
		genai.NewPartFromBytes(imageBytes, mimeType),
		genai.NewPartFromText(promptData.PromptText + "\nUser Data: " + userData),
	}, genai.RoleUser)

	resp, err := client.Models.GenerateContent(ctx, modelName, []*genai.Content{content}, &genai.GenerateContentConfig{
		ResponseMIMEType: "application/json",
	})
	if err != nil {
		return nil, 0, fmt.Errorf("generate nutrition from image: %w", err)
	}

	responseJSON := resp.Text()

	var totalTokens int
	if resp.UsageMetadata != nil {
		totalTokens = int(resp.UsageMetadata.TotalTokenCount)
	}

	return json.RawMessage(responseJSON), totalTokens, nil
}

// getTextModel reads the model name from system_settings (key: ai_text_model).
// Falls back to "gemini-3.1-flash-lite" if not set.
func (s *AIService) getTextModel(ctx context.Context, adminID *uuid.UUID) string {
	setting, err := s.repo.GetSystemSetting(ctx, "ai_text_model", adminID)
	if err != nil || setting.SettingValue == "" {
		return "gemini-3.1-flash-lite"
	}
	return setting.SettingValue
}

// getVisionModel reads the model name from system_settings (key: ai_vision_model).
// Falls back to "gemini-3.1-flash-lite" if not set.
func (s *AIService) getVisionModel(ctx context.Context, adminID *uuid.UUID) string {
	setting, err := s.repo.GetSystemSetting(ctx, "ai_vision_model", adminID)
	if err != nil || setting.SettingValue == "" {
		return "gemini-3.1-flash-lite"
	}
	return setting.SettingValue
}
