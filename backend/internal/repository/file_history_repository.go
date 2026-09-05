package repository

import (
	"path/filepath"
	"sort"

	"github.com/Gylmynnn/declient/be/internal/model"
)

type FileHistoryRepository struct {
	file string
}

func NewFileHistoryRepository(dataDir string) *FileHistoryRepository {
	return &FileHistoryRepository{file: filepath.Join(dataDir, "history.json")}
}

func (r *FileHistoryRepository) read() ([]model.HistoryEntry, error) {
	var out []model.HistoryEntry
	err := readJSONFile(r.file, &out, func() { out = []model.HistoryEntry{} })
	if out == nil {
		out = []model.HistoryEntry{}
	}
	return out, err
}

func (r *FileHistoryRepository) write(items []model.HistoryEntry) error {
	if items == nil {
		items = []model.HistoryEntry{}
	}
	return writeJSONFile(r.file, items)
}

func (r *FileHistoryRepository) GetAll(limit int) ([]model.HistoryEntry, error) {
	items, err := r.read()
	if err != nil {
		return nil, err
	}
	sort.Slice(items, func(i, j int) bool {
		return items[i].CreatedAt.Time.After(items[j].CreatedAt.Time)
	})
	if limit > 0 && len(items) > limit {
		items = items[:limit]
	}
	return items, nil
}

func (r *FileHistoryRepository) Create(h model.HistoryEntry) error {
	items, err := r.read()
	if err != nil {
		return err
	}
	items = append(items, h)
	// Keep only last 200 entries to bound file size.
	if len(items) > 200 {
		items = items[len(items)-200:]
	}
	return r.write(items)
}

func (r *FileHistoryRepository) Delete(id string) error {
	items, err := r.read()
	if err != nil {
		return err
	}
	for i := range items {
		if items[i].ID == id {
			items = append(items[:i], items[i+1:]...)
			return r.write(items)
		}
	}
	return nil
}

func (r *FileHistoryRepository) Clear() error {
	return r.write([]model.HistoryEntry{})
}

type FileMetaRepository struct {
	file string
}

func NewFileMetaRepository(dataDir string) *FileMetaRepository {
	return &FileMetaRepository{file: filepath.Join(dataDir, "meta.json")}
}

func (r *FileMetaRepository) Get() (model.Meta, error) {
	var m model.Meta
	if err := readJSONFile(r.file, &m, func() { m = model.Meta{} }); err != nil {
		return model.Meta{}, err
	}
	return m, nil
}

func (r *FileMetaRepository) SetActiveEnvironment(id string) error {
	return writeJSONFile(r.file, model.Meta{ActiveEnvironmentID: id})
}
