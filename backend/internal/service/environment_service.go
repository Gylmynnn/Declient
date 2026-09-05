package service

import (
	"github.com/Gylmynnn/declient/be/internal/model"
	"github.com/Gylmynnn/declient/be/internal/repository"
)

type EnvironmentServiceImpl struct {
	envs repository.EnvironmentRepository
	meta repository.MetaRepository
}

func NewEnvironmentService(e repository.EnvironmentRepository, m repository.MetaRepository) *EnvironmentServiceImpl {
	return &EnvironmentServiceImpl{envs: e, meta: m}
}

func (s *EnvironmentServiceImpl) GetAll() ([]model.Environment, error) {
	return s.envs.GetAll()
}

func (s *EnvironmentServiceImpl) GetByID(id string) (*model.Environment, error) {
	e, err := s.envs.GetByID(id)
	if err != nil {
		return nil, err
	}
	if e == nil {
		return nil, ErrNotFound
	}
	return e, nil
}

func (s *EnvironmentServiceImpl) Create(name string, vars []model.EnvVariable) (*model.Environment, error) {
	if name == "" {
		return nil, ErrNameRequired
	}
	if vars == nil {
		vars = []model.EnvVariable{}
	}
	e := model.Environment{
		ID:        GenerateID(),
		Name:      name,
		Variables: vars,
		CreatedAt: model.Now(),
		UpdatedAt: model.Now(),
	}
	e.EnsureDefaults()
	if err := s.envs.Create(e); err != nil {
		return nil, err
	}
	return &e, nil
}

func (s *EnvironmentServiceImpl) Update(id, name string, vars []model.EnvVariable) (*model.Environment, error) {
	e, err := s.GetByID(id)
	if err != nil {
		return nil, err
	}
	if name != "" {
		e.Name = name
	}
	if vars != nil {
		e.Variables = vars
	}
	e.UpdatedAt = model.Now()
	if err := s.envs.Update(*e); err != nil {
		return nil, err
	}
	return e, nil
}

func (s *EnvironmentServiceImpl) Delete(id string) error {
	if _, err := s.GetByID(id); err != nil {
		return err
	}
	if err := s.envs.Delete(id); err != nil {
		return err
	}
	meta, _ := s.meta.Get()
	if meta.ActiveEnvironmentID == id {
		_ = s.meta.SetActiveEnvironment("")
	}
	return nil
}

func (s *EnvironmentServiceImpl) GetActive() (*model.Environment, error) {
	meta, err := s.meta.Get()
	if err != nil {
		return nil, err
	}
	if meta.ActiveEnvironmentID == "" {
		return nil, nil
	}
	e, err := s.envs.GetByID(meta.ActiveEnvironmentID)
	if err != nil {
		return nil, err
	}
	return e, nil // may be nil if deleted
}

func (s *EnvironmentServiceImpl) SetActive(id string) error {
	if id != "" && !s.envs.Exists(id) {
		return ErrNotFound
	}
	return s.meta.SetActiveEnvironment(id)
}

func (s *EnvironmentServiceImpl) Resolve(text string, envID string) (string, error) {
	var env *model.Environment
	var err error
	if envID != "" {
		env, err = s.envs.GetByID(envID)
		if err != nil {
			return "", err
		}
	} else {
		env, err = s.GetActive()
		if err != nil {
			return "", err
		}
	}
	vars := BuildVarMap(env, nil)
	return ResolveVars(text, vars), nil
}
