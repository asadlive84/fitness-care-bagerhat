package notifier_test

import (
	"testing"
	"time"

	"github.com/asadlive84/fitness-care-bagerhat/internal/models"
	"github.com/asadlive84/fitness-care-bagerhat/internal/notifier"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

var dhaka = func() *time.Location {
	tz, _ := time.LoadLocation("Asia/Dhaka")
	return tz
}()

// crossMidnight is the typical quiet window (22:00–07:00 Dhaka time).
var crossMidnight = models.QuietWindow{Start: "22:00", End: "07:00"}

// daytime is a window that does NOT cross midnight (09:00–17:00).
var daytime = models.QuietWindow{Start: "09:00", End: "17:00"}

func dhakaTime(hour, minute int) time.Time {
	return time.Date(2026, 5, 16, hour, minute, 0, 0, dhaka)
}

func TestIsInQuietWindow_CrossMidnight_Inside(t *testing.T) {
	cases := []struct{ h, m int }{
		{22, 0}, {23, 30}, {0, 0}, {3, 0}, {6, 59},
	}
	for _, tc := range cases {
		assert.True(t, notifier.IsInQuietWindow(dhakaTime(tc.h, tc.m), crossMidnight, dhaka),
			"expected inside window at %02d:%02d", tc.h, tc.m)
	}
}

func TestIsInQuietWindow_CrossMidnight_Outside(t *testing.T) {
	cases := []struct{ h, m int }{
		{7, 0}, {7, 1}, {10, 0}, {12, 0}, {21, 59},
	}
	for _, tc := range cases {
		assert.False(t, notifier.IsInQuietWindow(dhakaTime(tc.h, tc.m), crossMidnight, dhaka),
			"expected outside window at %02d:%02d", tc.h, tc.m)
	}
}

func TestIsInQuietWindow_Daytime_Inside(t *testing.T) {
	cases := []struct{ h, m int }{{9, 0}, {12, 0}, {16, 59}}
	for _, tc := range cases {
		assert.True(t, notifier.IsInQuietWindow(dhakaTime(tc.h, tc.m), daytime, dhaka),
			"expected inside window at %02d:%02d", tc.h, tc.m)
	}
}

func TestIsInQuietWindow_Daytime_Outside(t *testing.T) {
	cases := []struct{ h, m int }{{8, 59}, {17, 0}, {20, 0}}
	for _, tc := range cases {
		assert.False(t, notifier.IsInQuietWindow(dhakaTime(tc.h, tc.m), daytime, dhaka),
			"expected outside window at %02d:%02d", tc.h, tc.m)
	}
}

func TestWindowEnd_CrossMidnight_During(t *testing.T) {
	// At 23:00 Dhaka, window ends at 07:00 next day.
	now := dhakaTime(23, 0)
	end := notifier.WindowEnd(now, crossMidnight, dhaka)

	endLocal := end.In(dhaka)
	require.True(t, end.After(now), "window end must be after now")
	assert.Equal(t, 7, endLocal.Hour())
	assert.Equal(t, 0, endLocal.Minute())
}

func TestWindowEnd_CrossMidnight_EarlyMorning(t *testing.T) {
	// At 03:00 Dhaka, window ends at 07:00 same day.
	now := dhakaTime(3, 0)
	end := notifier.WindowEnd(now, crossMidnight, dhaka)

	endLocal := end.In(dhaka)
	require.True(t, end.After(now))
	assert.Equal(t, 7, endLocal.Hour())
}

func TestIsInQuietWindow_BadConfig(t *testing.T) {
	bad := models.QuietWindow{Start: "invalid", End: "07:00"}
	// Should not panic; returns false (never suppress on bad config)
	assert.False(t, notifier.IsInQuietWindow(dhakaTime(23, 0), bad, dhaka))
}
