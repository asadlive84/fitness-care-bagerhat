package services

import (
	"context"
	"fmt"
	"mime/multipart"
	"path/filepath"
	"strings"
	"time"

	"github.com/aws/aws-sdk-go-v2/aws"
	awsconfig "github.com/aws/aws-sdk-go-v2/config"
	"github.com/aws/aws-sdk-go-v2/service/s3"
	"github.com/google/uuid"
)

type S3Uploader struct {
	client  *s3.Client
	bucket  string
	baseURL string
}

func NewS3Uploader(region, bucket, baseURL string) (*S3Uploader, error) {
	cfg, err := awsconfig.LoadDefaultConfig(context.Background(),
		awsconfig.WithRegion(region),
	)
	if err != nil {
		return nil, fmt.Errorf("load aws config: %w", err)
	}
	return &S3Uploader{
		client:  s3.NewFromConfig(cfg),
		bucket:  bucket,
		baseURL: baseURL,
	}, nil
}

func (u *S3Uploader) Upload(file *multipart.FileHeader) (string, error) {
	ext := strings.ToLower(filepath.Ext(file.Filename))
	key := fmt.Sprintf("uploads/%s_%d%s", uuid.New().String(), time.Now().Unix(), ext)

	src, err := file.Open()
	if err != nil {
		return "", fmt.Errorf("open file: %w", err)
	}
	defer src.Close()

	contentType := map[string]string{
		".jpg":  "image/jpeg",
		".jpeg": "image/jpeg",
		".png":  "image/png",
		".webp": "image/webp",
	}[ext]

	_, err = u.client.PutObject(context.Background(), &s3.PutObjectInput{
		Bucket:      aws.String(u.bucket),
		Key:         aws.String(key),
		Body:        src,
		ContentType: aws.String(contentType),
	})
	if err != nil {
		return "", fmt.Errorf("s3 put object: %w", err)
	}

	return fmt.Sprintf("%s/%s", strings.TrimRight(u.baseURL, "/"), key), nil
}
