package service

import (
	"fmt"
	"strings"

	"github.com/Gylmynnn/declient/be/internal/model"
	"github.com/Gylmynnn/declient/be/internal/repository"
)

type TransferServiceImpl struct {
	collections repository.CollectionRepository
	folders     repository.FolderRepository
	requests    repository.RequestRepository
	envs        repository.EnvironmentRepository
}

func NewTransferService(
	c repository.CollectionRepository,
	f repository.FolderRepository,
	r repository.RequestRepository,
	e repository.EnvironmentRepository,
) *TransferServiceImpl {
	return &TransferServiceImpl{collections: c, folders: f, requests: r, envs: e}
}

func (s *TransferServiceImpl) Export() (map[string]any, error) {
	cols, err := s.collections.GetAll()
	if err != nil {
		return nil, err
	}
	folders, err := s.folders.GetAll()
	if err != nil {
		return nil, err
	}
	reqs, err := s.requests.GetAll()
	if err != nil {
		return nil, err
	}
	envs, err := s.envs.GetAll()
	if err != nil {
		return nil, err
	}
	return map[string]any{
		"format":      "declient-1",
		"collections": cols,
		"folders":     folders,
		"requests":    reqs,
		"environments": envs,
	}, nil
}

func (s *TransferServiceImpl) ImportNative(data map[string]any) error {
	// Accepts output of Export(). Re-generates IDs to avoid collisions? Keep original IDs
	// if not colliding; simpler: keep IDs, skip existing.
	rawCols, _ := data["collections"].([]any)
	_ = rawCols
	// Re-marshal via generic helpers: use type assertion through JSON round-trip done by handler.
	// Handler decodes into typed struct, so this path is for map-based fallback.
	return fmt.Errorf("use typed import endpoint")
}

type nativeDump = NativeDump

func (s *TransferServiceImpl) ImportNativeTyped(dump NativeDump) error {
	for _, c := range dump.Collections {
		if c.ID == "" {
			c.ID = GenerateID()
		}
		if c.CreatedAt.IsZero() {
			c.CreatedAt = model.Now()
			c.UpdatedAt = model.Now()
		}
		if existing, _ := s.collections.GetByID(c.ID); existing == nil {
			_ = s.collections.Create(c)
		}
	}
	for _, f := range dump.Folders {
		if f.ID == "" {
			f.ID = GenerateID()
		}
		if existing, _ := s.folders.GetByID(f.ID); existing == nil {
			_ = s.folders.Create(f)
		}
	}
	for _, r := range dump.Requests {
		if r.ID == "" {
			r.ID = GenerateID()
		}
		r.EnsureDefaults()
		if existing, _ := s.requests.GetByID(r.ID); existing == nil {
			_ = s.requests.Create(r)
		}
	}
	for _, e := range dump.Environments {
		if e.ID == "" {
			e.ID = GenerateID()
		}
		e.EnsureDefaults()
		if existing, _ := s.envs.GetByID(e.ID); existing == nil {
			_ = s.envs.Create(e)
		}
	}
	return nil
}

// ImportPostman handles a subset of Postman Collection v2.1:
// { info: {name}, item: [ {name, request:{method,url,header,body}, item:[...]} ] }
func (s *TransferServiceImpl) ImportPostman(data map[string]any) (*model.Collection, error) {
	info, _ := data["info"].(map[string]any)
	name, _ := info["name"].(string)
	if name == "" {
		name = "Imported Collection"
	}
	col := model.Collection{
		ID:          GenerateID(),
		Name:        name,
		Description: "Imported from Postman",
		CreatedAt:   model.Now(),
		UpdatedAt:   model.Now(),
	}
	if err := s.collections.Create(col); err != nil {
		return nil, err
	}
	items, _ := data["item"].([]any)
	for _, it := range items {
		s.importPostmanItem(it, col.ID, "")
	}
	return &col, nil
}

func (s *TransferServiceImpl) importPostmanItem(raw any, collectionID, parentID string) {
	m, ok := raw.(map[string]any)
	if !ok {
		return
	}
	name, _ := m["name"].(string)
	if sub, ok := m["item"].([]any); ok {
		// It's a folder.
		f := model.Folder{
			ID:           GenerateID(),
			CollectionID: collectionID,
			ParentID:     parentID,
			Name:         name,
			CreatedAt:    model.Now(),
			UpdatedAt:    model.Now(),
		}
		_ = s.folders.Create(f)
		for _, child := range sub {
			s.importPostmanItem(child, collectionID, f.ID)
		}
		return
	}
	// It's a request.
	reqMap, ok := m["request"].(map[string]any)
	if !ok {
		return
	}
	method, _ := reqMap["method"].(string)
	if method == "" {
		method = "GET"
	}
	rawURL := ""
	switch u := reqMap["url"].(type) {
	case string:
		rawURL = u
	case map[string]any:
		if r, ok := u["raw"].(string); ok {
			rawURL = r
		}
	}
	headers := []model.KeyValue{}
	if hs, ok := reqMap["header"].([]any); ok {
		for _, h := range hs {
			if hm, ok := h.(map[string]any); ok {
				k, _ := hm["key"].(string)
				v, _ := hm["value"].(string)
				headers = append(headers, model.KeyValue{Key: k, Value: v, Enabled: true})
			}
		}
	}
	bodyType := "none"
	body := ""
	if bm, ok := reqMap["body"].(map[string]any); ok {
		mode, _ := bm["mode"].(string)
		switch strings.ToLower(mode) {
		case "raw":
			bodyType = "raw"
			body, _ = bm["raw"].(string)
		case "urlencoded":
			bodyType = "form"
		case "formdata":
			bodyType = "form"
		}
	}
	r := model.ApiRequest{
		ID:           GenerateID(),
		CollectionID: collectionID,
		FolderID:     parentID,
		Name:         name,
		Method:       normalizeMethod(method),
		URL:          rawURL,
		Headers:      headers,
		Params:       []model.KeyValue{},
		BodyType:     bodyType,
		Body:         body,
		Auth:         model.AuthConfig{Type: "none"},
		CreatedAt:    model.Now(),
		UpdatedAt:    model.Now(),
	}
	r.EnsureDefaults()
	_ = s.requests.Create(r)
}
