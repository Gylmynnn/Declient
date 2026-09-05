package service

import "github.com/Gylmynnn/declient/be/internal/model"

type CollectionService interface {
	GetAll() ([]model.Collection, error)
	GetByID(id string) (*model.Collection, error)
	Create(name, description string) (*model.Collection, error)
	Update(id, name, description string) (*model.Collection, error)
	Delete(id string) error
}

type FolderService interface {
	GetByCollection(collectionID string) ([]model.Folder, error)
	Create(collectionID, parentID, name, description string) (*model.Folder, error)
	Update(id, name, description string) (*model.Folder, error)
	Delete(id string) error
}

type RequestService interface {
	GetByCollection(collectionID string) ([]model.ApiRequest, error)
	GetByID(id string) (*model.ApiRequest, error)
	Create(req model.ApiRequest) (*model.ApiRequest, error)
	Update(req model.ApiRequest) (*model.ApiRequest, error)
	Delete(id string) error
	Send(id string, override *model.SendPayload) (*model.SendResult, error)
	SendAdhoc(payload model.SendPayload) (*model.SendResult, error)
}

type EnvironmentService interface {
	GetAll() ([]model.Environment, error)
	GetByID(id string) (*model.Environment, error)
	Create(name string, vars []model.EnvVariable) (*model.Environment, error)
	Update(id, name string, vars []model.EnvVariable) (*model.Environment, error)
	Delete(id string) error
	GetActive() (*model.Environment, error)
	SetActive(id string) error
	Resolve(text string, envID string) (string, error)
}

type HistoryService interface {
	GetAll(limit int) ([]model.HistoryEntry, error)
	Delete(id string) error
	Clear() error
}

type TransferService interface {
	Export() (map[string]any, error)
	ImportNative(data map[string]any) error
	ImportNativeTyped(dump NativeDump) error
	ImportPostman(data map[string]any) (*model.Collection, error)
}
