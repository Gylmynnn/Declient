package service

import (
	"github.com/Gylmynnn/declient/be/internal/model"
)

// NativeDump is the typed shape of DeClient export for import.
type NativeDump struct {
	Collections  []model.Collection  `json:"collections"`
	Folders      []model.Folder      `json:"folders"`
	Requests     []model.ApiRequest  `json:"requests"`
	Environments []model.Environment `json:"environments"`
}
