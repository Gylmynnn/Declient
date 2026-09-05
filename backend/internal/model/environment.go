package model

type EnvVariable struct {
	Key     string `json:"key"`
	Value   string `json:"value"`
	Enabled bool   `json:"enabled"`
}

type Environment struct {
	ID        string        `json:"id"`
	Name      string        `json:"name"`
	Variables []EnvVariable `json:"variables"`
	CreatedAt FlexibleTime  `json:"createdAt"`
	UpdatedAt FlexibleTime  `json:"updatedAt"`
}

func (e *Environment) EnsureDefaults() {
	if e.Variables == nil {
		e.Variables = []EnvVariable{}
	}
}

type Meta struct {
	ActiveEnvironmentID string `json:"activeEnvironmentId"`
}
