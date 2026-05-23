package handlers

import (
	"fmt"
	"log/slog"
	"path/filepath"
	"strings"
	"time"

	"github.com/asadlive84/fitness-care-bagerhat/internal/config"
	"github.com/asadlive84/fitness-care-bagerhat/internal/services"
	"github.com/asadlive84/fitness-care-bagerhat/internal/utils"
	"github.com/gofiber/fiber/v2"
	"github.com/google/uuid"
)

type UploadHandler struct {
	config     config.UploadConfig
	s3Uploader *services.S3Uploader
	log        *slog.Logger
}

func NewUploadHandler(cfg config.UploadConfig, log *slog.Logger) *UploadHandler {
	h := &UploadHandler{
		config: cfg,
		log:    log.With(slog.String("component", "upload_handler")),
	}

	if cfg.S3Bucket != "" && cfg.S3Region != "" {
		uploader, err := services.NewS3Uploader(cfg.S3Region, cfg.S3Bucket, cfg.S3BaseURL)
		if err != nil {
			log.Warn("S3 uploader init failed, falling back to local storage", "error", err)
		} else {
			h.s3Uploader = uploader
			log.Info("S3 upload enabled", "bucket", cfg.S3Bucket, "region", cfg.S3Region)
		}
	}

	return h
}

// HandleUpload receives a multipart/form-data file and saves it to S3 or locally.
//
//	@Summary		Upload an image
//	@Description	Upload an image file (e.g. food log or profile picture). Maximum size is configured via env (default 5MB).
//	@Tags			Uploads
//	@Accept			multipart/form-data
//	@Produce		json
//	@Security		BearerAuth
//	@Param			file	formData	file	true	"Image file"
//	@Success		200		{object}	response.Response{data=string} "Returns the public URL of the uploaded image"
//	@Failure		400		{object}	response.Response
//	@Failure		401		{object}	response.Response
//	@Failure		500		{object}	response.Response
//	@Router			/api/v1/upload [post]
func (h *UploadHandler) HandleUpload(c *fiber.Ctx) error {
	file, err := c.FormFile("file")
	if err != nil {
		return utils.ErrorResponse(c, fiber.StatusBadRequest, "BAD_REQUEST", "file is required", nil)
	}

	maxSize := h.config.MaxSizeMB * 1024 * 1024
	if file.Size > maxSize {
		return utils.ErrorResponse(c, fiber.StatusBadRequest, "BAD_REQUEST",
			fmt.Sprintf("file exceeds maximum size of %d MB", h.config.MaxSizeMB), nil)
	}

	ext := strings.ToLower(filepath.Ext(file.Filename))
	if ext != ".jpg" && ext != ".jpeg" && ext != ".png" && ext != ".webp" {
		return utils.ErrorResponse(c, fiber.StatusBadRequest, "BAD_REQUEST",
			"only .jpg, .jpeg, .png, and .webp files are allowed", nil)
	}

	// Upload to S3 if configured, otherwise save locally
	if h.s3Uploader != nil {
		publicURL, err := h.s3Uploader.Upload(file)
		if err != nil {
			h.log.Error("s3 upload failed", "error", err)
			return utils.ErrorResponse(c, fiber.StatusInternalServerError, "INTERNAL_ERROR", "failed to upload file", nil)
		}
		h.log.Info("file uploaded to S3", "url", publicURL, "size", file.Size)
		return utils.SuccessResponse(c, fiber.StatusOK, publicURL)
	}

	// Local fallback
	newFileName := fmt.Sprintf("%s_%d%s", uuid.New().String(), time.Now().Unix(), ext)
	savePath := filepath.Join(h.config.Dir, newFileName)
	if err := c.SaveFile(file, savePath); err != nil {
		h.log.Error("failed to save file locally", "error", err)
		return utils.ErrorResponse(c, fiber.StatusInternalServerError, "INTERNAL_ERROR", "failed to save file", nil)
	}
	publicURL := fmt.Sprintf("/uploads/%s", newFileName)
	h.log.Info("file uploaded locally", "url", publicURL, "size", file.Size)
	return utils.SuccessResponse(c, fiber.StatusOK, publicURL)
}
