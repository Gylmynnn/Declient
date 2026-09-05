package model

import (
	"encoding/json"
	"strings"
	"time"
)

// FlexibleTime mirrors detask behaviour: tolerant parsing, RFC3339 output.
type FlexibleTime struct {
	time.Time
}

func Now() FlexibleTime {
	return FlexibleTime{Time: time.Now()}
}

func (ft *FlexibleTime) UnmarshalJSON(data []byte) error {
	s := strings.Trim(string(data), "\"")
	if s == "null" || s == "" {
		return nil
	}

	formats := []string{
		time.RFC3339,
		"2006-01-02T15:04:05.000",
		"2006-01-02T15:04:05",
		"2006-01-02",
	}

	for _, format := range formats {
		if t, err := time.Parse(format, s); err == nil {
			ft.Time = t
			return nil
		}
	}

	return json.Unmarshal(data, &ft.Time)
}

func (ft FlexibleTime) MarshalJSON() ([]byte, error) {
	if ft.Time.IsZero() {
		return []byte("null"), nil
	}
	return json.Marshal(ft.Time.Format(time.RFC3339))
}
