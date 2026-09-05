package handler

import (
	"net/http"

	"github.com/Gylmynnn/declient/be/internal/service"
)

type CollectionHandler struct {
	collections service.CollectionService
	folders     service.FolderService
	requests    service.RequestService
}

func NewCollectionHandler(c service.CollectionService, f service.FolderService, r service.RequestService) *CollectionHandler {
	return &CollectionHandler{collections: c, folders: f, requests: r}
}

func (h *CollectionHandler) GetAll(w http.ResponseWriter, r *http.Request) {
	items, err := h.collections.GetAll()
	if err != nil {
		writeErr(w, http.StatusInternalServerError, "internal server error")
		return
	}
	writeJSON(w, http.StatusOK, items)
}

func (h *CollectionHandler) GetByID(w http.ResponseWriter, r *http.Request) {
	id := r.URL.Query().Get("id")
	col, err := h.collections.GetByID(id)
	if err != nil {
		handleServiceErr(w, err)
		return
	}
	folders, _ := h.folders.GetByCollection(id)
	requests, _ := h.requests.GetByCollection(id)
	writeJSON(w, http.StatusOK, map[string]any{
		"collection": col,
		"folders":    folders,
		"requests":   requests,
	})
}

func (h *CollectionHandler) Create(w http.ResponseWriter, r *http.Request) {
	var body struct {
		Name        string `json:"name"`
		Description string `json:"description"`
	}
	if err := decodeBody(r, &body); err != nil {
		writeErr(w, http.StatusBadRequest, "invalid request body")
		return
	}
	created, err := h.collections.Create(body.Name, body.Description)
	if err != nil {
		handleServiceErr(w, err)
		return
	}
	writeJSON(w, http.StatusCreated, created)
}

func (h *CollectionHandler) Update(w http.ResponseWriter, r *http.Request, id string) {
	var body struct {
		Name        string `json:"name"`
		Description string `json:"description"`
	}
	if err := decodeBody(r, &body); err != nil {
		writeErr(w, http.StatusBadRequest, "invalid request body")
		return
	}
	updated, err := h.collections.Update(id, body.Name, body.Description)
	if err != nil {
		handleServiceErr(w, err)
		return
	}
	writeJSON(w, http.StatusOK, updated)
}

func (h *CollectionHandler) Delete(w http.ResponseWriter, r *http.Request, id string) {
	if err := h.collections.Delete(id); err != nil {
		handleServiceErr(w, err)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}
