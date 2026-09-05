package service

import (
	"bytes"
	"encoding/base64"
	"fmt"
	"io"
	"mime/multipart"
	"net/http"
	"net/textproto"
	"net/url"
	"strings"
	"time"

	"github.com/Gylmynnn/declient/be/internal/model"
	"github.com/Gylmynnn/declient/be/internal/repository"
)

type RequestServiceImpl struct {
	requests repository.RequestRepository
	envs     repository.EnvironmentRepository
	meta     repository.MetaRepository
	history  repository.HistoryRepository
	client   *http.Client
}

func NewRequestService(
	r repository.RequestRepository,
	e repository.EnvironmentRepository,
	m repository.MetaRepository,
	h repository.HistoryRepository,
) *RequestServiceImpl {
	return &RequestServiceImpl{
		requests: r,
		envs:     e,
		meta:     m,
		history:  h,
		client:   &http.Client{Timeout: 30 * time.Second},
	}
}

func (s *RequestServiceImpl) activeVars(envID string) (map[string]string, *model.Environment) {
	var env *model.Environment
	if envID != "" {
		env, _ = s.envs.GetByID(envID)
	} else {
		meta, _ := s.meta.Get()
		if meta.ActiveEnvironmentID != "" {
			env, _ = s.envs.GetByID(meta.ActiveEnvironmentID)
		}
	}
	return BuildVarMap(env, nil), env
}

func (s *RequestServiceImpl) GetByCollection(collectionID string) ([]model.ApiRequest, error) {
	return s.requests.GetByCollection(collectionID)
}

func (s *RequestServiceImpl) GetByID(id string) (*model.ApiRequest, error) {
	r, err := s.requests.GetByID(id)
	if err != nil {
		return nil, err
	}
	if r == nil {
		return nil, ErrNotFound
	}
	return r, nil
}

func (s *RequestServiceImpl) Create(req model.ApiRequest) (*model.ApiRequest, error) {
	if req.URL == "" {
		return nil, ErrInvalidURL
	}
	req.Method = normalizeMethod(req.Method)
	if !validMethods[req.Method] {
		return nil, ErrInvalidMethod
	}
	req.EnsureDefaults()
	req.ID = GenerateID()
	req.CreatedAt = model.Now()
	req.UpdatedAt = model.Now()
	if err := s.requests.Create(req); err != nil {
		return nil, err
	}
	return &req, nil
}

func (s *RequestServiceImpl) Update(req model.ApiRequest) (*model.ApiRequest, error) {
	existing, err := s.GetByID(req.ID)
	if err != nil {
		return nil, err
	}
	req.Method = normalizeMethod(req.Method)
	if !validMethods[req.Method] {
		return nil, ErrInvalidMethod
	}
	req.EnsureDefaults()
	req.CreatedAt = existing.CreatedAt
	req.UpdatedAt = model.Now()
	// Preserve collection binding if empty.
	if req.CollectionID == "" {
		req.CollectionID = existing.CollectionID
	}
	if err := s.requests.Update(req); err != nil {
		return nil, err
	}
	return &req, nil
}

func (s *RequestServiceImpl) Delete(id string) error {
	if _, err := s.GetByID(id); err != nil {
		return err
	}
	return s.requests.Delete(id)
}

func (s *RequestServiceImpl) Send(id string, override *model.SendPayload) (*model.SendResult, error) {
	stored, err := s.GetByID(id)
	if err != nil {
		return nil, err
	}
	payload := model.SendPayload{
		Method:   stored.Method,
		URL:      stored.URL,
		Params:   stored.Params,
		Headers:  stored.Headers,
		BodyType: stored.BodyType,
		Body:     stored.Body,
		FormData: stored.FormData,
		Auth:     stored.Auth,
	}
	envID := ""
	if override != nil {
		if override.Method != "" {
			payload.Method = override.Method
		}
		if override.URL != "" {
			payload.URL = override.URL
		}
		if override.Params != nil {
			payload.Params = override.Params
		}
		if override.Headers != nil {
			payload.Headers = override.Headers
		}
		if override.BodyType != "" {
			payload.BodyType = override.BodyType
		}
		if override.Body != "" || override.BodyType != "" {
			payload.Body = override.Body
		}
		if override.FormData != nil {
			payload.FormData = override.FormData
		}
		if override.Auth.Type != "" {
			payload.Auth = override.Auth
		}
		envID = override.EnvironmentID
	}
	result, err := s.execute(payload, envID)
	if err != nil {
		return nil, err
	}
	_ = s.history.Create(model.HistoryEntry{
		ID:          GenerateID(),
		RequestID:   stored.ID,
		RequestName: stored.Name,
		Method:      normalizeMethod(payload.Method),
		URL:         payload.URL,
		ResolvedURL: result.ResolvedURL,
		StatusCode:  result.StatusCode,
		DurationMs:  result.DurationMs,
		Size:        result.Size,
		CreatedAt:   model.Now(),
	})
	return result, nil
}

func (s *RequestServiceImpl) SendAdhoc(payload model.SendPayload) (*model.SendResult, error) {
	if payload.URL == "" {
		return nil, ErrInvalidURL
	}
	result, err := s.execute(payload, payload.EnvironmentID)
	if err != nil {
		return nil, err
	}
	_ = s.history.Create(model.HistoryEntry{
		ID:          GenerateID(),
		RequestName: fmt.Sprintf("%s %s", normalizeMethod(payload.Method), payload.URL),
		Method:      normalizeMethod(payload.Method),
		URL:         payload.URL,
		ResolvedURL: result.ResolvedURL,
		StatusCode:  result.StatusCode,
		DurationMs:  result.DurationMs,
		Size:        result.Size,
		CreatedAt:   model.Now(),
	})
	return result, nil
}

func (s *RequestServiceImpl) execute(payload model.SendPayload, envID string) (*model.SendResult, error) {
	method := normalizeMethod(payload.Method)
	if !validMethods[method] {
		return nil, ErrInvalidMethod
	}
	vars, _ := s.activeVars(envID)

	resolvedURL := ResolveVars(payload.URL, vars)
	params := ResolveKeyValues(payload.Params, vars)
	headers := ResolveKeyValues(payload.Headers, vars)
	bodyStr := ResolveVars(payload.Body, vars)

	// Merge params into URL query.
	u, err := url.Parse(resolvedURL)
	if err != nil {
		return nil, fmt.Errorf("invalid url: %w", err)
	}
	if u.Scheme == "" || u.Host == "" {
		return nil, fmt.Errorf("invalid url: scheme and host required")
	}
	q := u.Query()
	for _, p := range params {
		if !p.Enabled || p.Key == "" {
			continue
		}
		q.Add(p.Key, p.Value)
	}
	u.RawQuery = q.Encode()
	finalURL := u.String()

	var bodyReader io.Reader
	var multipartCT string
	if method != "GET" && method != "HEAD" {
		if payload.BodyType == "multipart" {
			ct, buf, err := buildMultipartBody(payload.FormData, vars)
			if err != nil {
				return nil, err
			}
			multipartCT = ct
			if len(buf) > 0 {
				bodyReader = bytes.NewBuffer(buf)
			}
		} else if bodyStr != "" {
			bodyReader = bytes.NewBufferString(bodyStr)
		}
	}

	req, err := http.NewRequest(method, finalURL, bodyReader)
	if err != nil {
		return nil, err
	}
	for _, h := range headers {
		if !h.Enabled || h.Key == "" {
			continue
		}
		req.Header.Set(h.Key, h.Value)
	}
	// Auth handling.
	authType := strings.ToLower(payload.Auth.Type)
	switch authType {
	case "bearer":
		token := ResolveVars(payload.Auth.Token, vars)
		if token != "" {
			req.Header.Set("Authorization", "Bearer "+token)
		}
	case "basic":
		user := ResolveVars(payload.Auth.Username, vars)
		pass := ResolveVars(payload.Auth.Password, vars)
		req.SetBasicAuth(user, pass)
	}
	if bodyReader != nil && req.Header.Get("Content-Type") == "" {
		switch payload.BodyType {
		case "json":
			req.Header.Set("Content-Type", "application/json")
		case "text", "raw":
			req.Header.Set("Content-Type", "text/plain")
		case "form":
			req.Header.Set("Content-Type", "application/x-www-form-urlencoded")
		}
	}
	if multipartCT != "" {
		// Boundary multipart wajib dari writer; timpa header user jika ada.
		req.Header.Set("Content-Type", multipartCT)
	}

	start := time.Now()
	resp, err := s.client.Do(req)
	if err != nil {
		return nil, err
	}
	defer resp.Body.Close()
	limited := io.LimitReader(resp.Body, 5<<20) // 5MB cap
	respBytes, _ := io.ReadAll(limited)
	duration := time.Since(start)

	respHeaders := map[string]string{}
	for k, vv := range resp.Header {
		respHeaders[k] = strings.Join(vv, ", ")
	}

	return &model.SendResult{
		StatusCode:  resp.StatusCode,
		Headers:     respHeaders,
		Body:        string(respBytes),
		DurationMs:  duration.Milliseconds(),
		Size:        int64(len(respBytes)),
		ResolvedURL: finalURL,
	}, nil
}

type HistoryServiceImpl struct {
	history repository.HistoryRepository
}

// escapeMultipartQuotes meng-escape kutip untuk parameter Content-Disposition.
func escapeMultipartQuotes(s string) string {
	s = strings.ReplaceAll(s, "\\", "\\\\")
	return strings.ReplaceAll(s, `"`, "\\\"")
}

// buildMultipartBody merakit body multipart/form-data dari fields.
// Mengembalikan content-type (termasuk boundary) + body. Field bertipe file
// membawa isi file sebagai base64 di FileBase64. Key/value text melewati
// ResolveVars agar mendukung {{variable}} environment.
func buildMultipartBody(fields []model.FormField, vars map[string]string) (string, []byte, error) {
	var buf bytes.Buffer
	w := multipart.NewWriter(&buf)
	for _, f := range fields {
		if !f.Enabled || f.Key == "" {
			continue
		}
		key := ResolveVars(f.Key, vars)
		if key == "" {
			continue
		}
		if strings.ToLower(f.Type) == "file" {
			raw, err := base64.StdEncoding.DecodeString(f.FileBase64)
			if err != nil {
				return "", nil, fmt.Errorf("field %q: base64 file tidak valid: %w", key, err)
			}
			name := f.FileName
			if name == "" {
				name = "file"
			}
			h := textproto.MIMEHeader{}
			h.Set("Content-Disposition", fmt.Sprintf(`form-data; name="%s"; filename="%s"`, escapeMultipartQuotes(key), escapeMultipartQuotes(name)))
			ct := f.ContentType
			if ct == "" {
				ct = "application/octet-stream"
			}
			h.Set("Content-Type", ct)
			part, err := w.CreatePart(h)
			if err != nil {
				return "", nil, err
			}
			if _, err := part.Write(raw); err != nil {
				return "", nil, err
			}
			continue
		}
		if err := w.WriteField(key, ResolveVars(f.Value, vars)); err != nil {
			return "", nil, err
		}
	}
	if err := w.Close(); err != nil {
		return "", nil, err
	}
	return w.FormDataContentType(), buf.Bytes(), nil
}

func NewHistoryService(h repository.HistoryRepository) *HistoryServiceImpl {
	return &HistoryServiceImpl{history: h}
}

func (s *HistoryServiceImpl) GetAll(limit int) ([]model.HistoryEntry, error) {
	return s.history.GetAll(limit)
}

func (s *HistoryServiceImpl) Delete(id string) error {
	return s.history.Delete(id)
}

func (s *HistoryServiceImpl) Clear() error {
	return s.history.Clear()
}
