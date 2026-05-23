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

// SeedDefaultPrompts seeds fallback prompts and model settings globally on first startup if they do not exist.
func (s *AIService) SeedDefaultPrompts(ctx context.Context) error {
	defaultPrompts := map[string]string{
		"diet_generation_prompt": `You are an expert nutritionist. Generate a personalized, daily diet plan for the user in JSON format.
The JSON must strictly conform to the following schema:
{
  "daily_calories": 2000,
  "macros": {
    "protein": 150,
    "carbs": 200,
    "fats": 65
  },
  "meals": [
    {
      "name": "Breakfast",
      "time": "08:30 AM",
      "calories": 500,
      "protein": 35,
      "carbs": 55,
      "fats": 15,
      "items": [
        "3 egg whites and 1 whole egg",
        "1 cup cooked oatmeal",
        "1 medium banana"
      ]
    }
  ]
}
Make sure all time strings are formatted in "HH:MM AM/PM" 12-hour format. Do not add any markdown blocks or extra explanation; output ONLY valid raw JSON.`,
		"food_validation_prompt": `Analyze this image and return a JSON containing calories, protein, carbs, and fats.`,
	}

	for pType, pText := range defaultPrompts {
		_, err := s.repo.GetAIPrompt(ctx, pType, nil)
		if err != nil {
			s.log.Info("Seeding default AI prompt for the first time", "type", pType)
			_ = s.repo.UpdateAIPromptGlobal(ctx, pType, pText, true)
		}
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

// GenerateDietChart calls Gemini to generate a personalized diet chart.
// language: "en" for English, "bn" for Bangla.
func (s *AIService) GenerateDietChart(ctx context.Context, member *models.Member, language string) (json.RawMessage, int, error) {
	promptData, err := s.repo.GetAIPrompt(ctx, "diet_generation_prompt", member.CreatedByAdminID)
	if err != nil {
		promptData = sqlcdb.AiPrompt{
			PromptText: `You are an expert nutritionist. Generate a personalized, daily diet plan for the user in JSON format.
The JSON must strictly conform to the following schema:
{
  "daily_calories": 2000,
  "macros": {
    "protein": 150,
    "carbs": 200,
    "fats": 65
  },
  "meals": [
    {
      "name": "Breakfast",
      "time": "08:30 AM",
      "calories": 500,
      "protein": 35,
      "carbs": 55,
      "fats": 15,
      "items": [
        "3 egg whites and 1 whole egg",
        "1 cup cooked oatmeal",
        "1 medium banana"
      ]
    }
  ]
}
Make sure all time strings are formatted in "HH:MM AM/PM" 12-hour format. Do not add any markdown blocks or extra explanation; output ONLY valid raw JSON.`,
		}
	}

	goalVal := "Not set"
	if member.Goal != nil {
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
	budgetVal := "Medium"
	if member.BudgetLevel != nil {
		budgetVal = *member.BudgetLevel
	}
	ageVal := "Not set"
	if member.DateOfBirth != nil {
		years := time.Now().Year() - member.DateOfBirth.Year()
		if time.Now().YearDay() < member.DateOfBirth.YearDay() {
			years--
		}
		ageVal = fmt.Sprintf("%d years old", years)
	}
	hobbiesVal := "None"
	if len(member.Hobbies) > 0 {
		hobbiesVal = strings.Join(member.Hobbies, ", ")
	}

	userData := fmt.Sprintf("Gender: %s, Age: %s, Height: %s, Weight: %s, Goal/Target: %s, Physical Activities/Issues/Hobbies: %s, Budget Level: %s",
		member.Gender, ageVal, heightVal, weightVal, goalVal, hobbiesVal, budgetVal)

	langInstruction := "Generate the entire diet plan in English."
	if language == "bn" {
		langInstruction = "সম্পূর্ণ ডায়েট প্ল্যানটি বাংলায় তৈরি করুন। সকল meal নাম, খাবারের নাম এবং বিবরণ বাংলায় লিখুন।"
	}

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
		genai.Text(promptData.PromptText+"\nUser Data: "+userData+"\nLanguage Instruction: "+langInstruction),
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
