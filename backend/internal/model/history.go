package model

type HistoryEntry struct {
	ID          string       `json:"id"`
	RequestID   string       `json:"requestId,omitempty"`
	RequestName string       `json:"requestName"`
	Method      string       `json:"method"`
	URL         string       `json:"url"`
	ResolvedURL string       `json:"resolvedUrl"`
	StatusCode  int          `json:"statusCode"`
	DurationMs  int64        `json:"durationMs"`
	Size        int64        `json:"size"`
	CreatedAt   FlexibleTime `json:"createdAt"`
}
