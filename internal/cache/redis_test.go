package cache_test

import (
	"context"
	"testing"

	"github.com/asadlive84/fitness-care-bagerhat/internal/cache"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

// TestErrCacheMiss verifies ErrCacheMiss is returned for absent keys.
// Requires a running Redis at localhost:6379 — skipped otherwise.
func TestErrCacheMiss(t *testing.T) {
	// Try to connect; skip cleanly if Redis is not available.
	cfg := testRedisConfig()
	client, err := cache.New(cfg)
	if err != nil {
		t.Skipf("redis not available: %v", err)
	}
	defer client.Close()

	ctx := context.Background()
	_, err = client.Get(ctx, "test:nonexistent:key:12345")
	require.Error(t, err)
	assert.ErrorIs(t, err, cache.ErrCacheMiss)
}

// TestSetGetDelete tests the basic set → get → delete → miss cycle.
func TestSetGetDelete(t *testing.T) {
	cfg := testRedisConfig()
	client, err := cache.New(cfg)
	if err != nil {
		t.Skipf("redis not available: %v", err)
	}
	defer client.Close()

	ctx := context.Background()
	key := "test:set_get_delete"

	require.NoError(t, client.Set(ctx, key, "hello", 60*1_000_000_000)) // 60s

	val, err := client.Get(ctx, key)
	require.NoError(t, err)
	assert.Equal(t, "hello", val)

	require.NoError(t, client.Delete(ctx, key))

	_, err = client.Get(ctx, key)
	assert.ErrorIs(t, err, cache.ErrCacheMiss)
}

// TestSetGetJSON tests JSON round-trip helpers.
func TestSetGetJSON(t *testing.T) {
	cfg := testRedisConfig()
	client, err := cache.New(cfg)
	if err != nil {
		t.Skipf("redis not available: %v", err)
	}
	defer client.Close()

	ctx := context.Background()
	key := "test:json"
	type payload struct {
		Name string `json:"name"`
		Age  int    `json:"age"`
	}

	src := payload{Name: "Karim", Age: 30}
	require.NoError(t, client.SetJSON(ctx, key, src, 60*1_000_000_000))
	defer client.Delete(ctx, key) //nolint:errcheck

	var dst payload
	require.NoError(t, client.GetJSON(ctx, key, &dst))
	assert.Equal(t, src, dst)
}
