package repository

import (
	"path/filepath"

	"github.com/Gylmynnn/declient/be/internal/model"
)

type FileEnvironmentRepository struct {
	file string
}

func NewFileEnvironmentRepository(dataDir string) *FileEnvironmentRepository {
	return &FileEnvironmentRepository{file: filepath.Join(dataDir, "environments.json")}
}

func (r *FileEnvironmentRepository) read() ([]model.Environment, error) {
	var out []model.Environment
	err := readJSONFile(r.file, &out, func() { out = []model.Environment{} })
	if out == nil {
		out = []model.Environment{}
	}
	return out, err
}

func (r *FileEnvironmentRepository) write(items []model.Environment) error {
	if items == nil {
		items = []model.Environment{}
	}
	return writeJSONFile(r.file, items)
}

func (r *FileEnvironmentRepository) GetAll() ([]model.Environment, error) {
	return r.read()
}

func (r *FileEnvironmentRepository) GetByID(id string) (*model.Environment, error) {
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

func (r *FileEnvironmentRepository) Create(e model.Environment) error {
	items, err := r.read()
	if err != nil {
		return err
	}
	items = append(items, e)
	return r.write(items)
}

func (r *FileEnvironmentRepository) Update(e model.Environment) error {
	items, err := r.read()
	if err != nil {
		return err
	}
	for i := range items {
		if items[i].ID == e.ID {
			items[i] = e
			return r.write(items)
		}
	}
	return nil
}

func (r *FileEnvironmentRepository) Delete(id string) error {
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

func (r *FileEnvironmentRepository) Exists(id string) bool {
	e, _ := r.GetByID(id)
	return e != nil
}
