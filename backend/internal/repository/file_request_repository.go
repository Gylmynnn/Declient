package repository

import (
	"path/filepath"

	"github.com/Gylmynnn/declient/be/internal/model"
)

type FileRequestRepository struct {
	file string
}

func NewFileRequestRepository(dataDir string) *FileRequestRepository {
	return &FileRequestRepository{file: filepath.Join(dataDir, "requests.json")}
}

func (r *FileRequestRepository) read() ([]model.ApiRequest, error) {
	var out []model.ApiRequest
	err := readJSONFile(r.file, &out, func() { out = []model.ApiRequest{} })
	if out == nil {
		out = []model.ApiRequest{}
	}
	return out, err
}

func (r *FileRequestRepository) write(items []model.ApiRequest) error {
	if items == nil {
		items = []model.ApiRequest{}
	}
	return writeJSONFile(r.file, items)
}

func (r *FileRequestRepository) GetAll() ([]model.ApiRequest, error) {
	return r.read()
}

func (r *FileRequestRepository) GetByCollection(collectionID string) ([]model.ApiRequest, error) {
	items, err := r.read()
	if err != nil {
		return nil, err
	}
	out := []model.ApiRequest{}
	for _, req := range items {
		if req.CollectionID == collectionID {
			out = append(out, req)
		}
	}
	return out, nil
}

func (r *FileRequestRepository) GetByID(id string) (*model.ApiRequest, error) {
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

func (r *FileRequestRepository) Create(req model.ApiRequest) error {
	items, err := r.read()
	if err != nil {
		return err
	}
	items = append(items, req)
	return r.write(items)
}

func (r *FileRequestRepository) Update(req model.ApiRequest) error {
	items, err := r.read()
	if err != nil {
		return err
	}
	for i := range items {
		if items[i].ID == req.ID {
			items[i] = req
			return r.write(items)
		}
	}
	return nil
}

func (r *FileRequestRepository) Delete(id string) error {
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

func (r *FileRequestRepository) DeleteByCollection(collectionID string) error {
	items, err := r.read()
	if err != nil {
		return err
	}
	kept := []model.ApiRequest{}
	for _, req := range items {
		if req.CollectionID != collectionID {
			kept = append(kept, req)
		}
	}
	return r.write(kept)
}

func (r *FileRequestRepository) DeleteByFolder(folderID string) error {
	items, err := r.read()
	if err != nil {
		return err
	}
	kept := []model.ApiRequest{}
	for _, req := range items {
		if req.FolderID != folderID {
			kept = append(kept, req)
		}
	}
	return r.write(kept)
}
