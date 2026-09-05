package repository

import (
	"path/filepath"

	"github.com/Gylmynnn/declient/be/internal/model"
)

type FileCollectionRepository struct {
	file string
}

func NewFileCollectionRepository(dataDir string) *FileCollectionRepository {
	return &FileCollectionRepository{file: filepath.Join(dataDir, "collections.json")}
}

func (r *FileCollectionRepository) read() ([]model.Collection, error) {
	var out []model.Collection
	err := readJSONFile(r.file, &out, func() { out = []model.Collection{} })
	if out == nil {
		out = []model.Collection{}
	}
	return out, err
}

func (r *FileCollectionRepository) write(items []model.Collection) error {
	if items == nil {
		items = []model.Collection{}
	}
	return writeJSONFile(r.file, items)
}

func (r *FileCollectionRepository) GetAll() ([]model.Collection, error) {
	return r.read()
}

func (r *FileCollectionRepository) GetByID(id string) (*model.Collection, error) {
	items, err := r.read()
	if err != nil {
		return nil, err
	}
	for i := range items {
		if items[i].ID == id {
			return &items[i], nil
		}
	}
	return nil, nil
}

func (r *FileCollectionRepository) Create(c model.Collection) error {
	items, err := r.read()
	if err != nil {
		return err
	}
	items = append(items, c)
	return r.write(items)
}

func (r *FileCollectionRepository) Update(c model.Collection) error {
	items, err := r.read()
	if err != nil {
		return err
	}
	for i := range items {
		if items[i].ID == c.ID {
			items[i] = c
			return r.write(items)
		}
	}
	return nil
}

func (r *FileCollectionRepository) Delete(id string) error {
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

func (r *FileCollectionRepository) Exists(id string) bool {
	c, _ := r.GetByID(id)
	return c != nil
}
