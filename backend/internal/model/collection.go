package model

type Collection struct {
	ID          string       `json:"id"`
	Name        string       `json:"name"`
	Description string       `json:"description"`
	CreatedAt   FlexibleTime `json:"createdAt"`
	UpdatedAt   FlexibleTime `json:"updatedAt"`
}
