package repository

import "github.com/Gylmynnn/declient/be/internal/model"

type CollectionRepository interface {
	GetAll() ([]model.Collection, error)
	GetByID(id string) (*model.Collection, error)
	Create(c model.Collection) error
	Update(c model.Collection) error
	Delete(id string) error
	Exists(id string) bool
}

type FolderRepository interface {
	GetAll() ([]model.Folder, error)
	GetByCollection(collectionID string) ([]model.Folder, error)
	GetByID(id string) (*model.Folder, error)
	Create(f model.Folder) error
	Update(f model.Folder) error
	Delete(id string) error
	DeleteByCollection(collectionID string) error
}

type RequestRepository interface {
	GetAll() ([]model.ApiRequest, error)
	GetByCollection(collectionID string) ([]model.ApiRequest, error)
	GetByID(id string) (*model.ApiRequest, error)
	Create(r model.ApiRequest) error
	Update(r model.ApiRequest) error
	Delete(id string) error
	DeleteByCollection(collectionID string) error
	DeleteByFolder(folderID string) error
}

type EnvironmentRepository interface {
	GetAll() ([]model.Environment, error)
	GetByID(id string) (*model.Environment, error)
	Create(e model.Environment) error
	Update(e model.Environment) error
	Delete(id string) error
	Exists(id string) bool
}

type HistoryRepository interface {
	GetAll(limit int) ([]model.HistoryEntry, error)
	Create(h model.HistoryEntry) error
	Delete(id string) error
	Clear() error
}

type MetaRepository interface {
	Get() (model.Meta, error)
	SetActiveEnvironment(id string) error
}
