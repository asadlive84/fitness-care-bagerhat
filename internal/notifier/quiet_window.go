package notifier

import (
	"fmt"
	"time"

	"github.com/asadlive84/fitness-care-bagerhat/internal/models"
)

// IsInQuietWindow reports whether now (converted to tz) falls within the
// configured quiet window. Windows that cross midnight (e.g. 22:00–07:00)
// are handled correctly.
func IsInQuietWindow(now time.Time, window models.QuietWindow, tz *time.Location) bool {
	local := now.In(tz)
	cur := local.Hour()*60 + local.Minute()

	start, err1 := parseHHMM(window.Start)
	end, err2 := parseHHMM(window.End)
	if err1 != nil || err2 != nil {
		return false // bad config → never suppress
	}

	if start > end {
		// Crosses midnight: e.g. 22:00 → 07:00
		return cur >= start || cur < end
	}
	return cur >= start && cur < end
}

// WindowEnd returns the time at which the quiet window ends (in UTC).
// Call this when IsInQuietWindow is true to know when to reschedule.
func WindowEnd(now time.Time, window models.QuietWindow, tz *time.Location) time.Time {
	local := now.In(tz)
	end, err := parseHHMM(window.End)
	if err != nil {
		return now.Add(8 * time.Hour) // safe fallback
	}

	endH := end / 60
	endM := end % 60

	candidate := time.Date(local.Year(), local.Month(), local.Day(), endH, endM, 0, 0, tz)
	if !candidate.After(local) {
		candidate = candidate.Add(24 * time.Hour)
	}
	return candidate.UTC()
}

// parseHHMM converts "HH:MM" to minutes-since-midnight.
func parseHHMM(s string) (int, error) {
	var h, m int
	if _, err := fmt.Sscanf(s, "%d:%d", &h, &m); err != nil {
		return 0, fmt.Errorf("invalid time %q: %w", s, err)
	}
	if h < 0 || h > 23 || m < 0 || m > 59 {
		return 0, fmt.Errorf("time out of range: %q", s)
	}
	return h*60 + m, nil
}
