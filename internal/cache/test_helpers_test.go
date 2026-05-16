package cache_test

import (
	"time"

	"github.com/asadlive84/fitness-care-bagerhat/internal/config"
)

func testRedisConfig() config.RedisConfig {
	return config.RedisConfig{
		Addr:         "localhost:6379",
		DB:           15, // isolated test DB
		DialTimeout:  2 * time.Second,
		ReadTimeout:  200 * time.Millisecond,
		WriteTimeout: 200 * time.Millisecond,
		PoolSize:     2,
	}
}
