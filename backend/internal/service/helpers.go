package service

import (
	"crypto/rand"
	"encoding/hex"
	"errors"
	"strings"
	"time"
)

var (
	ErrNotFound      = errors.New("not found")
	ErrNameRequired  = errors.New("name is required")
	ErrInvalidMethod = errors.New("invalid http method")
	ErrInvalidURL    = errors.New("url is required")
)

func GenerateID() string {
	b := make([]byte, 8)
	_, _ = rand.Read(b)
	return hex.EncodeToString(b) + "-" + time.Now().Format("20060102150405")
}

var validMethods = map[string]bool{
	"GET": true, "POST": true, "PUT": true, "PATCH": true,
	"DELETE": true, "HEAD": true, "OPTIONS": true,
}

func normalizeMethod(m string) string {
	if m == "" {
		return "GET"
	}
	return strings.ToUpper(m)
}
