package handler

import (
	"encoding/json"
	"errors"
	"net/http"

	"github.com/Gylmynnn/declient/be/internal/service"
)

func writeJSON(w http.ResponseWriter, status int, v any) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(status)
	_ = json.NewEncoder(w).Encode(v)
}

func writeErr(w http.ResponseWriter, status int, msg string) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(status)
	_ = json.NewEncoder(w).Encode(map[string]string{"error": msg})
}

func handleServiceErr(w http.ResponseWriter, err error) {
	switch {
	case errors.Is(err, service.ErrNotFound):
		writeErr(w, http.StatusNotFound, "not found")
	case errors.Is(err, service.ErrNameRequired):
		writeErr(w, http.StatusBadRequest, "name is required")
	case errors.Is(err, service.ErrInvalidMethod):
		writeErr(w, http.StatusBadRequest, "invalid http method")
	case errors.Is(err, service.ErrInvalidURL):
		writeErr(w, http.StatusBadRequest, "url is required")
	default:
		writeErr(w, http.StatusInternalServerError, "internal server error")
	}
}

func decodeBody(r *http.Request, v any) error {
	defer r.Body.Close()
	return json.NewDecoder(r.Body).Decode(v)
}
