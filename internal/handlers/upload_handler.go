package handlers

import (
	"fmt"
	"log/slog"
	"path/filepath"
	"strings"
	"time"

	"github.com/asadlive84/fitness-care-bagerhat/internal/config"
	"github.com/asadlive84/fitness-care-bagerhat/internal/utils"
	"github.com/gofiber/fiber/v2"
	"github.com/google/uuid"
)

type UploadHandler struct {
	config config.UploadConfig
	log    *slog.Logger
}

func NewUploadHandler(cfg config.UploadConfig, log *slog.Logger) *UploadHandler {
	return &UploadHandler{
		config: cfg,
		log:    log.With(slog.String("component", "upload_handler")),
	}
}

// HandleUpload receives a multipart/form-data file and saves it locally.
// It returns the public URL to access the image.
//
//	@Summary		Upload an image
//	@Description	Upload an image file (e.g. food log or profile picture). Maximum size is configured via env (default 5MB).
//	@Tags			Uploads
//	@Accept			multipart/form-data
//	@Produce		json
//	@Security		BearerAuth
//	@Param			file	formData	file	true	"Image file"
//	@Success		200		{object}	response.Response{data=string} "Returns the relative URL of the uploaded image"
//	@Failure		400		{object}	response.Response
//	@Failure		401		{object}	response.Response
//	@Failure		500		{object}	response.Response
//	@Router			/api/v1/upload [post]
func (h *UploadHandler) HandleUpload(c *fiber.Ctx) error {
	file, err := c.FormFile("file")
	if err != nil {
		h.log.Warn("failed to get file from form", "error", err)
		return utils.ErrorResponse(c, fiber.StatusBadRequest, "BAD_REQUEST", "file is required", nil)
	}

	// Validate file size
	maxSize := h.config.MaxSizeMB * 1024 * 1024
	if file.Size > maxSize {
		h.log.Warn("file too large", "size", file.Size, "max", maxSize)
		return utils.ErrorResponse(c, fiber.StatusBadRequest, "BAD_REQUEST", fmt.Sprintf("file exceeds maximum size of %d MB", h.config.MaxSizeMB), nil)
	}

	// Validate file extension
	ext := strings.ToLower(filepath.Ext(file.Filename))
	if ext != ".jpg" && ext != ".jpeg" && ext != ".png" && ext != ".webp" {
		h.log.Warn("invalid file extension", "ext", ext)
		return utils.ErrorResponse(c, fiber.StatusBadRequest, "BAD_REQUEST", "only .jpg, .jpeg, .png, and .webp files are allowed", nil)
	}

	// Generate a unique filename: <uuid>_<timestamp><ext>
	newFileName := fmt.Sprintf("%s_%d%s", uuid.New().String(), time.Now().Unix(), ext)
	savePath := filepath.Join(h.config.Dir, newFileName)

	// Save the file
	if err := c.SaveFile(file, savePath); err != nil {
		h.log.Error("failed to save file", "error", err, "path", savePath)
		return utils.ErrorResponse(c, fiber.StatusInternalServerError, "INTERNAL_ERROR", "failed to save file", nil)
	}

	// Return the relative URL (e.g. /uploads/filename.jpg)
	publicURL := fmt.Sprintf("/uploads/%s", newFileName)

	h.log.Info("file uploaded successfully", "url", publicURL, "size", file.Size)
	return utils.SuccessResponse(c, fiber.StatusOK, publicURL)
}
