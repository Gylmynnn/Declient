package model

type Folder struct {
	ID           string       `json:"id"`
	CollectionID string       `json:"collectionId"`
	ParentID     string       `json:"parentId,omitempty"`
	Name         string       `json:"name"`
	Description  string       `json:"description"`
	CreatedAt    FlexibleTime `json:"createdAt"`
	UpdatedAt    FlexibleTime `json:"updatedAt"`
}
