package handler

import (
	"net/http"

	"github.com/Gylmynnn/declient/be/internal/model"
	"github.com/Gylmynnn/declient/be/internal/service"
)

type RequestHandler struct {
	requests service.RequestService
}

func NewRequestHandler(r service.RequestService) *RequestHandler {
	return &RequestHandler{requests: r}
}

func (h *RequestHandler) GetByCollection(w http.ResponseWriter, r *http.Request) {
	collectionID := r.URL.Query().Get("collectionId")
	if collectionID == "" {
		collectionID = r.URL.Query().Get("id")
	}
	items, err := h.requests.GetByCollection(collectionID)
	if err != nil {
		writeErr(w, http.StatusInternalServerError, "internal server error")
		return
	}
	writeJSON(w, http.StatusOK, items)
}

func (h *RequestHandler) GetByID(w http.ResponseWriter, r *http.Request, id string) {
	req, err := h.requests.GetByID(id)
	if err != nil {
		handleServiceErr(w, err)
		return
	}
	writeJSON(w, http.StatusOK, req)
}

func (h *RequestHandler) Create(w http.ResponseWriter, r *http.Request) {
	var body model.ApiRequest
	if q := r.URL.Query().Get("id"); q != "" && body.CollectionID == "" {
		// filled after decode
		_ = q
	}
	if err := decodeBody(r, &body); err != nil {
		writeErr(w, http.StatusBadRequest, "invalid request body")
		return
	}
	if body.CollectionID == "" {
		if q := r.URL.Query().Get("collectionId"); q != "" {
			body.CollectionID = q
		} else if q := r.URL.Query().Get("id"); q != "" {
			body.CollectionID = q
		}
	}
	created, err := h.requests.Create(body)
	if err != nil {
		handleServiceErr(w, err)
		return
	}
	writeJSON(w, http.StatusCreated, created)
}

func (h *RequestHandler) Update(w http.ResponseWriter, r *http.Request, id string) {
	var body model.ApiRequest
	if err := decodeBody(r, &body); err != nil {
		writeErr(w, http.StatusBadRequest, "invalid request body")
		return
	}
	body.ID = id
	updated, err := h.requests.Update(body)
	if err != nil {
		handleServiceErr(w, err)
		return
	}
	writeJSON(w, http.StatusOK, updated)
}

func (h *RequestHandler) Delete(w http.ResponseWriter, r *http.Request, id string) {
	if err := h.requests.Delete(id); err != nil {
		handleServiceErr(w, err)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}

func (h *RequestHandler) Send(w http.ResponseWriter, r *http.Request, id string) {
	var override model.SendPayload
	_ = decodeBody(r, &override)
	result, err := h.requests.Send(id, &override)
	if err != nil {
		if msg := err.Error(); len(msg) >= 7 && msg[:7] == "invalid" {
			writeErr(w, http.StatusBadRequest, msg)
			return
		}
		// Distinguish domain errors from upstream transport errors.
		switch err {
		case service.ErrNotFound, service.ErrInvalidMethod, service.ErrInvalidURL:
			handleServiceErr(w, err)
		default:
			writeErr(w, http.StatusBadGateway, err.Error())
		}
		return
	}
	writeJSON(w, http.StatusOK, result)
}

func (h *RequestHandler) SendAdhoc(w http.ResponseWriter, r *http.Request) {
	var payload model.SendPayload
	if err := decodeBody(r, &payload); err != nil {
		writeErr(w, http.StatusBadRequest, "invalid request body")
		return
	}
	result, err := h.requests.SendAdhoc(payload)
	if err != nil {
		msg := err.Error()
		if len(msg) >= 7 && (msg[:7] == "invalid") {
			writeErr(w, http.StatusBadRequest, msg)
			return
		}
		writeErr(w, http.StatusBadGateway, msg)
		return
	}
	writeJSON(w, http.StatusOK, result)
}
