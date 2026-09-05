package model

type KeyValue struct {
	Key     string `json:"key"`
	Value   string `json:"value"`
	Enabled bool   `json:"enabled"`
}

type AuthConfig struct {
	Type     string `json:"type"`
	Token    string `json:"token,omitempty"`
	Username string `json:"username,omitempty"`
	Password string `json:"password,omitempty"`
}

// FormField adalah satu part multipart/form-data.
// Type "text": Value dikirim sebagai field biasa.
// Type "file": FileBase64 (base64 isi file) di-decode dan dikirim sebagai file
// dengan FileName + ContentType.
type FormField struct {
	Key         string `json:"key"`
	Value       string `json:"value,omitempty"`
	Type        string `json:"type,omitempty"` // text | file
	FileName    string `json:"fileName,omitempty"`
	ContentType string `json:"contentType,omitempty"`
	FileBase64  string `json:"fileBase64,omitempty"`
	Enabled     bool   `json:"enabled"`
}

type ApiRequest struct {
	ID           string       `json:"id"`
	CollectionID string       `json:"collectionId"`
	FolderID     string       `json:"folderId,omitempty"`
	Name         string       `json:"name"`
	Description  string       `json:"description"`
	Method       string       `json:"method"`
	URL          string       `json:"url"`
	Params       []KeyValue   `json:"params"`
	Headers      []KeyValue   `json:"headers"`
	BodyType     string       `json:"bodyType"`
	Body         string       `json:"body"`
	FormData     []FormField  `json:"formData"`
	Auth         AuthConfig   `json:"auth"`
	CreatedAt    FlexibleTime `json:"createdAt"`
	UpdatedAt    FlexibleTime `json:"updatedAt"`
}

func (r *ApiRequest) EnsureDefaults() {
	if r.Params == nil {
		r.Params = []KeyValue{}
	}
	if r.Headers == nil {
		r.Headers = []KeyValue{}
	}
	if r.FormData == nil {
		r.FormData = []FormField{}
	}
	if r.Method == "" {
		r.Method = "GET"
	}
	if r.BodyType == "" {
		r.BodyType = "none"
	}
	if r.Auth.Type == "" {
		r.Auth.Type = "none"
	}
}

// SendPayload is used for ad-hoc send and overrides.
type SendPayload struct {
	Method        string      `json:"method"`
	URL           string      `json:"url"`
	Params        []KeyValue  `json:"params"`
	Headers       []KeyValue  `json:"headers"`
	BodyType      string      `json:"bodyType"`
	Body          string      `json:"body"`
	FormData      []FormField `json:"formData"`
	Auth          AuthConfig  `json:"auth"`
	EnvironmentID string      `json:"environmentId,omitempty"`
}

type SendResult struct {
	StatusCode  int               `json:"statusCode"`
	Headers     map[string]string `json:"headers"`
	Body        string            `json:"body"`
	DurationMs  int64             `json:"durationMs"`
	Size        int64             `json:"size"`
	ResolvedURL string            `json:"resolvedUrl"`
}
