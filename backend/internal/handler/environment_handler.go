package handler

import (
	"net/http"

	"github.com/Gylmynnn/declient/be/internal/model"
	"github.com/Gylmynnn/declient/be/internal/service"
)

type EnvironmentHandler struct {
	envs service.EnvironmentService
}

func NewEnvironmentHandler(e service.EnvironmentService) *EnvironmentHandler {
	return &EnvironmentHandler{envs: e}
}

func (h *EnvironmentHandler) GetAll(w http.ResponseWriter, r *http.Request) {
	items, err := h.envs.GetAll()
	if err != nil {
		writeErr(w, http.StatusInternalServerError, "internal server error")
		return
	}
	writeJSON(w, http.StatusOK, items)
}

func (h *EnvironmentHandler) GetActive(w http.ResponseWriter, r *http.Request) {
	env, err := h.envs.GetActive()
	if err != nil {
		writeErr(w, http.StatusInternalServerError, "internal server error")
		return
	}
	writeJSON(w, http.StatusOK, map[string]any{"active": env})
}

func (h *EnvironmentHandler) GetByID(w http.ResponseWriter, r *http.Request, id string) {
	env, err := h.envs.GetByID(id)
	if err != nil {
		handleServiceErr(w, err)
		return
	}
	writeJSON(w, http.StatusOK, env)
}

func (h *EnvironmentHandler) Create(w http.ResponseWriter, r *http.Request) {
	var body struct {
		Name      string              `json:"name"`
		Variables []model.EnvVariable `json:"variables"`
	}
	if err := decodeBody(r, &body); err != nil {
		writeErr(w, http.StatusBadRequest, "invalid request body")
		return
	}
	created, err := h.envs.Create(body.Name, body.Variables)
	if err != nil {
		handleServiceErr(w, err)
		return
	}
	writeJSON(w, http.StatusCreated, created)
}

func (h *EnvironmentHandler) Update(w http.ResponseWriter, r *http.Request, id string) {
	var body struct {
		Name      string              `json:"name"`
		Variables []model.EnvVariable `json:"variables"`
	}
	if err := decodeBody(r, &body); err != nil {
		writeErr(w, http.StatusBadRequest, "invalid request body")
		return
	}
	updated, err := h.envs.Update(id, body.Name, body.Variables)
	if err != nil {
		handleServiceErr(w, err)
		return
	}
	writeJSON(w, http.StatusOK, updated)
}

func (h *EnvironmentHandler) Delete(w http.ResponseWriter, r *http.Request, id string) {
	if err := h.envs.Delete(id); err != nil {
		handleServiceErr(w, err)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}

func (h *EnvironmentHandler) SetActive(w http.ResponseWriter, r *http.Request, id string) {
	var body struct {
		ID string `json:"id"`
	}
	_ = decodeBody(r, &body)
	target := id
	if target == "" {
		target = body.ID
	}
	if target == "" {
		// Allow clearing active env.
		_ = h.envs.SetActive("")
		writeJSON(w, http.StatusOK, map[string]any{"activeEnvironmentId": ""})
		return
	}
	if err := h.envs.SetActive(target); err != nil {
		handleServiceErr(w, err)
		return
	}
	writeJSON(w, http.StatusOK, map[string]any{"activeEnvironmentId": target})
}

func (h *EnvironmentHandler) Resolve(w http.ResponseWriter, r *http.Request) {
	var body struct {
		Text          string `json:"text"`
		EnvironmentID string `json:"environmentId"`
	}
	if err := decodeBody(r, &body); err != nil {
		writeErr(w, http.StatusBadRequest, "invalid request body")
		return
	}
	resolved, err := h.envs.Resolve(body.Text, body.EnvironmentID)
	if err != nil {
		handleServiceErr(w, err)
		return
	}
	writeJSON(w, http.StatusOK, map[string]string{"resolved": resolved})
}
