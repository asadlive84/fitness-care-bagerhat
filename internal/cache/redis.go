package cache

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"time"

	"github.com/asadlive84/fitness-care-bagerhat/internal/config"
	"github.com/redis/go-redis/v9"
)

// ErrCacheMiss is returned when a key is not found in the cache.
var ErrCacheMiss = errors.New("cache miss")

// Client wraps redis.Client with opinionated helpers.
type Client struct {
	rdb     *redis.Client
	timeout time.Duration // default command timeout
}

// New creates and validates a Redis client.
func New(cfg config.RedisConfig) (*Client, error) {
	rdb := redis.NewClient(&redis.Options{
		Addr:         cfg.Addr,
		Password:     cfg.Password,
		DB:           cfg.DB,
		DialTimeout:  cfg.DialTimeout,
		ReadTimeout:  cfg.ReadTimeout,
		WriteTimeout: cfg.WriteTimeout,
		PoolSize:     cfg.PoolSize,
	})

	// Verify connectivity at startup.
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	if err := rdb.Ping(ctx).Err(); err != nil {
		return nil, fmt.Errorf("ping redis: %w", err)
	}

	return &Client{rdb: rdb, timeout: cfg.ReadTimeout}, nil
}

// Close gracefully closes the Redis connection pool.
func (c *Client) Close() error {
	return c.rdb.Close()
}

// Ping checks Redis connectivity. Returns nil if healthy.
func (c *Client) Ping(ctx context.Context) error {
	ctx, cancel := context.WithTimeout(ctx, 2*time.Second)
	defer cancel()
	return c.rdb.Ping(ctx).Err()
}

// Get returns the string value at key, or ErrCacheMiss if absent.
func (c *Client) Get(ctx context.Context, key string) (string, error) {
	ctx, cancel := context.WithTimeout(ctx, c.timeout)
	defer cancel()

	val, err := c.rdb.Get(ctx, key).Result()
	if errors.Is(err, redis.Nil) {
		return "", ErrCacheMiss
	}
	if err != nil {
		return "", fmt.Errorf("cache get %q: %w", key, err)
	}
	return val, nil
}

// Set stores a string value with a TTL. Always requires a TTL.
func (c *Client) Set(ctx context.Context, key, value string, ttl time.Duration) error {
	ctx, cancel := context.WithTimeout(ctx, c.timeout)
	defer cancel()

	if err := c.rdb.Set(ctx, key, value, ttl).Err(); err != nil {
		return fmt.Errorf("cache set %q: %w", key, err)
	}
	return nil
}

// Delete removes one or more keys. Silently ignores missing keys.
func (c *Client) Delete(ctx context.Context, keys ...string) error {
	ctx, cancel := context.WithTimeout(ctx, c.timeout)
	defer cancel()

	if err := c.rdb.Del(ctx, keys...).Err(); err != nil {
		return fmt.Errorf("cache delete: %w", err)
	}
	return nil
}

// GetJSON deserialises the value at key into dst, or returns ErrCacheMiss.
func (c *Client) GetJSON(ctx context.Context, key string, dst any) error {
	raw, err := c.Get(ctx, key)
	if err != nil {
		return err // already ErrCacheMiss or wrapped redis error
	}
	if err := json.Unmarshal([]byte(raw), dst); err != nil {
		return fmt.Errorf("cache unmarshal %q: %w", key, err)
	}
	return nil
}

// SetJSON serialises src to JSON and stores it with a TTL.
func (c *Client) SetJSON(ctx context.Context, key string, src any, ttl time.Duration) error {
	data, err := json.Marshal(src)
	if err != nil {
		return fmt.Errorf("cache marshal %q: %w", key, err)
	}
	return c.Set(ctx, key, string(data), ttl)
}
