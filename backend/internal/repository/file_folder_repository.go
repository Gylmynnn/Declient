package repository

import (
	"path/filepath"

	"github.com/Gylmynnn/declient/be/internal/model"
)

type FileFolderRepository struct {
	file string
}

func NewFileFolderRepository(dataDir string) *FileFolderRepository {
	return &FileFolderRepository{file: filepath.Join(dataDir, "folders.json")}
}

func (r *FileFolderRepository) read() ([]model.Folder, error) {
	var out []model.Folder
	err := readJSONFile(r.file, &out, func() { out = []model.Folder{} })
	if out == nil {
		out = []model.Folder{}
	}
	return out, err
}

func (r *FileFolderRepository) write(items []model.Folder) error {
	if items == nil {
		items = []model.Folder{}
	}
	return writeJSONFile(r.file, items)
}

func (r *FileFolderRepository) GetAll() ([]model.Folder, error) {
	return r.read()
}

func (r *FileFolderRepository) GetByCollection(collectionID string) ([]model.Folder, error) {
	items, err := r.read()
	if err != nil {
		return nil, err
	}
	out := []model.Folder{}
	for _, f := range items {
		if f.CollectionID == collectionID {
			out = append(out, f)
		}
	}
	return out, nil
}

func (r *FileFolderRepository) GetByID(id string) (*model.Folder, error) {
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

func (r *FileFolderRepository) Create(f model.Folder) error {
	items, err := r.read()
	if err != nil {
		return err
	}
	items = append(items, f)
	return r.write(items)
}

func (r *FileFolderRepository) Update(f model.Folder) error {
	items, err := r.read()
	if err != nil {
		return err
	}
	for i := range items {
		if items[i].ID == f.ID {
			items[i] = f
			return r.write(items)
		}
	}
	return nil
}

func (r *FileFolderRepository) Delete(id string) error {
	items, err := r.read()
	if err != nil {
		return err
	}
	// Collect ids to delete: the folder itself + nested children.
	toDelete := map[string]bool{id: true}
	changed := true
	for changed {
		changed = false
		for _, f := range items {
			if !toDelete[f.ID] && toDelete[f.ParentID] {
				toDelete[f.ID] = true
				changed = true
			}
		}
	}
	kept := []model.Folder{}
	for _, f := range items {
		if !toDelete[f.ID] {
			kept = append(kept, f)
		}
	}
	return r.write(kept)
}

func (r *FileFolderRepository) DeleteByCollection(collectionID string) error {
	items, err := r.read()
	if err != nil {
		return err
	}
	kept := []model.Folder{}
	for _, f := range items {
		if f.CollectionID != collectionID {
			kept = append(kept, f)
		}
	}
	return r.write(kept)
}
