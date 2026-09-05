package repository

import (
	"encoding/json"
	"os"
	"path/filepath"
)

func readJSONFile(path string, v any, fallback func()) error {
	data, err := os.ReadFile(path)
	if err != nil {
		if os.IsNotExist(err) {
			if fallback != nil {
				fallback()
			}
			return nil
		}
		return err
	}
	if len(data) == 0 {
		if fallback != nil {
			fallback()
		}
		return nil
	}
	if err := json.Unmarshal(data, v); err != nil {
		return err
	}
	return nil
}

func writeJSONFile(path string, v any) error {
	if err := os.MkdirAll(filepath.Dir(path), 0755); err != nil {
		return err
	}
	data, err := json.MarshalIndent(v, "", "  ")
	if err != nil {
		return err
	}
	return os.WriteFile(path, data, 0644)
}
