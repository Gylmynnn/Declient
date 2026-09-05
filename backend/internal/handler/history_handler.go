package handler

import (
	"encoding/json"
	"net/http"
	"strconv"

	"github.com/Gylmynnn/declient/be/internal/service"
)

type HistoryHandler struct {
	history service.HistoryService
}

func NewHistoryHandler(h service.HistoryService) *HistoryHandler {
	return &HistoryHandler{history: h}
}

func (h *HistoryHandler) GetAll(w http.ResponseWriter, r *http.Request) {
	limit := 50
	if l := r.URL.Query().Get("limit"); l != "" {
		if n, err := strconv.Atoi(l); err == nil {
			limit = n
		}
	}
	items, err := h.history.GetAll(limit)
	if err != nil {
		writeErr(w, http.StatusInternalServerError, "internal server error")
		return
	}
	writeJSON(w, http.StatusOK, items)
}

func (h *HistoryHandler) Delete(w http.ResponseWriter, r *http.Request, id string) {
	if err := h.history.Delete(id); err != nil {
		writeErr(w, http.StatusInternalServerError, "internal server error")
		return
	}
	w.WriteHeader(http.StatusNoContent)
}

func (h *HistoryHandler) Clear(w http.ResponseWriter, r *http.Request) {
	if err := h.history.Clear(); err != nil {
		writeErr(w, http.StatusInternalServerError, "internal server error")
		return
	}
	w.WriteHeader(http.StatusNoContent)
}

type TransferHandler struct {
	transfer service.TransferService
}

func NewTransferHandler(t service.TransferService) *TransferHandler {
	return &TransferHandler{transfer: t}
}

func (h *TransferHandler) Export(w http.ResponseWriter, r *http.Request) {
	data, err := h.transfer.Export()
	if err != nil {
		writeErr(w, http.StatusInternalServerError, "internal server error")
		return
	}
	writeJSON(w, http.StatusOK, data)
}

func (h *TransferHandler) Import(w http.ResponseWriter, r *http.Request) {
	format := r.URL.Query().Get("format")
	var raw map[string]any
	if err := decodeBody(r, &raw); err != nil {
		writeErr(w, http.StatusBadRequest, "invalid request body")
		return
	}
	if format == "postman" {
		col, err := h.transfer.ImportPostman(raw)
		if err != nil {
			writeErr(w, http.StatusInternalServerError, "internal server error")
			return
		}
		writeJSON(w, http.StatusCreated, col)
		return
	}
	writeJSON(w, http.StatusBadRequest, map[string]string{"error": "use /api/import/native for native format, /api/import?format=postman for postman"})
}

func (h *TransferHandler) ImportNative(w http.ResponseWriter, r *http.Request) {
	var dump service.NativeDump
	dec := json.NewDecoder(r.Body)
	defer r.Body.Close()
	if err := dec.Decode(&dump); err != nil {
		writeErr(w, http.StatusBadRequest, "invalid request body")
		return
	}
	if err := h.transfer.ImportNativeTyped(dump); err != nil {
		writeErr(w, http.StatusInternalServerError, "internal server error")
		return
	}
	writeJSON(w, http.StatusCreated, map[string]string{"status": "imported"})
}
