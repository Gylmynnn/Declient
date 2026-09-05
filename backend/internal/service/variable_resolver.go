package service

import (
	"regexp"

	"github.com/Gylmynnn/declient/be/internal/model"
)

var varPattern = regexp.MustCompile(`\{\{\s*([a-zA-Z0-9_\-.]+)\s*\}\}`)

func BuildVarMap(env *model.Environment, extra []model.EnvVariable) map[string]string {
	m := map[string]string{}
	if env != nil {
		for _, v := range env.Variables {
			if v.Enabled && v.Key != "" {
				m[v.Key] = v.Value
			}
		}
	}
	for _, v := range extra {
		if v.Enabled && v.Key != "" {
			m[v.Key] = v.Value
		}
	}
	return m
}

func ResolveVars(text string, vars map[string]string) string {
	return varPattern.ReplaceAllStringFunc(text, func(match string) string {
		key := varPattern.ReplaceAllString(match, "$1")
		if val, ok := vars[key]; ok {
			return val
		}
		return match
	})
}

func ResolveKeyValues(items []model.KeyValue, vars map[string]string) []model.KeyValue {
	out := make([]model.KeyValue, len(items))
	for i, kv := range items {
		kv.Key = ResolveVars(kv.Key, vars)
		kv.Value = ResolveVars(kv.Value, vars)
		out[i] = kv
	}
	return out
}
