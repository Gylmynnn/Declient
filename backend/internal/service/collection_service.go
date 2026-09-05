package service

import (
	"github.com/Gylmynnn/declient/be/internal/model"
	"github.com/Gylmynnn/declient/be/internal/repository"
)

type CollectionServiceImpl struct {
	collections repository.CollectionRepository
	folders     repository.FolderRepository
	requests    repository.RequestRepository
}

func NewCollectionService(
	c repository.CollectionRepository,
	f repository.FolderRepository,
	r repository.RequestRepository,
) *CollectionServiceImpl {
	return &CollectionServiceImpl{collections: c, folders: f, requests: r}
}

func (s *CollectionServiceImpl) GetAll() ([]model.Collection, error) {
	return s.collections.GetAll()
}

func (s *CollectionServiceImpl) GetByID(id string) (*model.Collection, error) {
	c, err := s.collections.GetByID(id)
	if err != nil {
		return nil, err
	}
	if c == nil {
		return nil, ErrNotFound
	}
	return c, nil
}

func (s *CollectionServiceImpl) Create(name, description string) (*model.Collection, error) {
	if name == "" {
		return nil, ErrNameRequired
	}
	c := model.Collection{
		ID:          GenerateID(),
		Name:        name,
		Description: description,
		CreatedAt:   model.Now(),
		UpdatedAt:   model.Now(),
	}
	if err := s.collections.Create(c); err != nil {
		return nil, err
	}
	return &c, nil
}

func (s *CollectionServiceImpl) Update(id, name, description string) (*model.Collection, error) {
	c, err := s.GetByID(id)
	if err != nil {
		return nil, err
	}
	if name != "" {
		c.Name = name
	}
	c.Description = description
	c.UpdatedAt = model.Now()
	if err := s.collections.Update(*c); err != nil {
		return nil, err
	}
	return c, nil
}

func (s *CollectionServiceImpl) Delete(id string) error {
	if _, err := s.GetByID(id); err != nil {
		return err
	}
	_ = s.requests.DeleteByCollection(id)
	_ = s.folders.DeleteByCollection(id)
	return s.collections.Delete(id)
}

type FolderServiceImpl struct {
	collections repository.CollectionRepository
	folders     repository.FolderRepository
	requests    repository.RequestRepository
}

func NewFolderService(
	c repository.CollectionRepository,
	f repository.FolderRepository,
	r repository.RequestRepository,
) *FolderServiceImpl {
	return &FolderServiceImpl{collections: c, folders: f, requests: r}
}

func (s *FolderServiceImpl) GetByCollection(collectionID string) ([]model.Folder, error) {
	return s.folders.GetByCollection(collectionID)
}

func (s *FolderServiceImpl) Create(collectionID, parentID, name, description string) (*model.Folder, error) {
	if name == "" {
		return nil, ErrNameRequired
	}
	if !s.collections.Exists(collectionID) {
		return nil, ErrNotFound
	}
	f := model.Folder{
		ID:           GenerateID(),
		CollectionID: collectionID,
		ParentID:     parentID,
		Name:         name,
		Description:  description,
		CreatedAt:    model.Now(),
		UpdatedAt:    model.Now(),
	}
	if err := s.folders.Create(f); err != nil {
		return nil, err
	}
	return &f, nil
}

func (s *FolderServiceImpl) Update(id, name, description string) (*model.Folder, error) {
	f, err := s.folders.GetByID(id)
	if err != nil {
		return nil, err
	}
	if f == nil {
		return nil, ErrNotFound
	}
	if name != "" {
		f.Name = name
	}
	f.Description = description
	f.UpdatedAt = model.Now()
	if err := s.folders.Update(*f); err != nil {
		return nil, err
	}
	return f, nil
}

func (s *FolderServiceImpl) Delete(id string) error {
	f, err := s.folders.GetByID(id)
	if err != nil {
		return err
	}
	if f == nil {
		return ErrNotFound
	}
	// Delete requests directly in this folder (nested folders handled via folder cascade;
	// requests in nested folders are cleaned by collecting descendant ids).
	allFolders, _ := s.folders.GetAll()
	descendants := []string{id}
	for _, fld := range allFolders {
		for _, d := range descendants {
			if fld.ParentID == d {
				descendants = append(descendants, fld.ID)
				break
			}
		}
	}
	for _, d := range descendants {
		_ = s.requests.DeleteByFolder(d)
	}
	return s.folders.Delete(id)
}
