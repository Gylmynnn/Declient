package handler

import (
	"net/http"

	"github.com/Gylmynnn/declient/be/internal/service"
)

type FolderHandler struct {
	folders service.FolderService
}

func NewFolderHandler(f service.FolderService) *FolderHandler {
	return &FolderHandler{folders: f}
}

func (h *FolderHandler) GetByCollection(w http.ResponseWriter, r *http.Request) {
	collectionID := r.URL.Query().Get("collectionId")
	if collectionID == "" {
		collectionID = r.URL.Query().Get("id")
	}
	items, err := h.folders.GetByCollection(collectionID)
	if err != nil {
		writeErr(w, http.StatusInternalServerError, "internal server error")
		return
	}
	writeJSON(w, http.StatusOK, items)
}

func (h *FolderHandler) Create(w http.ResponseWriter, r *http.Request) {
	var body struct {
		CollectionID string `json:"collectionId"`
		ParentID     string `json:"parentId"`
		Name         string `json:"name"`
		Description  string `json:"description"`
	}
	// Allow collectionId via query for nested route.
	if q := r.URL.Query().Get("collectionId"); q != "" && body.CollectionID == "" {
		body.CollectionID = q
	}
	if q := r.URL.Query().Get("id"); q != "" {
		body.CollectionID = q
	}
	if err := decodeBody(r, &body); err != nil {
		writeErr(w, http.StatusBadRequest, "invalid request body")
		return
	}
	// Re-check query after decode (decode overwrites).
	if body.CollectionID == "" {
		if q := r.URL.Query().Get("collectionId"); q != "" {
			body.CollectionID = q
		} else if q := r.URL.Query().Get("id"); q != "" {
			body.CollectionID = q
		}
	}
	created, err := h.folders.Create(body.CollectionID, body.ParentID, body.Name, body.Description)
	if err != nil {
		handleServiceErr(w, err)
		return
	}
	writeJSON(w, http.StatusCreated, created)
}

func (h *FolderHandler) Update(w http.ResponseWriter, r *http.Request, id string) {
	var body struct {
		Name        string `json:"name"`
		Description string `json:"description"`
	}
	if err := decodeBody(r, &body); err != nil {
		writeErr(w, http.StatusBadRequest, "invalid request body")
		return
	}
	updated, err := h.folders.Update(id, body.Name, body.Description)
	if err != nil {
		handleServiceErr(w, err)
		return
	}
	writeJSON(w, http.StatusOK, updated)
}

func (h *FolderHandler) Delete(w http.ResponseWriter, r *http.Request, id string) {
	if err := h.folders.Delete(id); err != nil {
		handleServiceErr(w, err)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}
