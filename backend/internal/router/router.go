package router

import (
	"net/http"
	"strings"
)

type route struct {
	method  string
	pattern string
	handler http.HandlerFunc
}

type Router struct {
	routes     []route
	middleware func(http.Handler) http.Handler
}

func New() *Router {
	return &Router{}
}

func (rt *Router) Use(mw func(http.Handler) http.Handler) {
	rt.middleware = mw
}

func (rt *Router) Handle(method, pattern string, handler http.HandlerFunc) {
	rt.routes = append(rt.routes, route{
		method:  method,
		pattern: pattern,
		handler: handler,
	})
}

func (rt *Router) GET(pattern string, handler http.HandlerFunc) {
	rt.Handle(http.MethodGet, pattern, handler)
}

func (rt *Router) POST(pattern string, handler http.HandlerFunc) {
	rt.Handle(http.MethodPost, pattern, handler)
}

func (rt *Router) PUT(pattern string, handler http.HandlerFunc) {
	rt.Handle(http.MethodPut, pattern, handler)
}

func (rt *Router) PATCH(pattern string, handler http.HandlerFunc) {
	rt.Handle(http.MethodPatch, pattern, handler)
}

func (rt *Router) DELETE(pattern string, handler http.HandlerFunc) {
	rt.Handle(http.MethodDelete, pattern, handler)
}

func (rt *Router) match(method, path string) (http.HandlerFunc, map[string]string) {
	for _, r := range rt.routes {
		if r.method != method {
			continue
		}

		params := matchPattern(r.pattern, path)
		if params != nil {
			return r.handler, params
		}
	}
	return nil, nil
}

func matchPattern(pattern, path string) map[string]string {
	patternParts := strings.Split(strings.Trim(pattern, "/"), "/")
	pathParts := strings.Split(strings.Trim(path, "/"), "/")

	if len(patternParts) != len(pathParts) {
		return nil
	}

	params := make(map[string]string)
	for i, pp := range patternParts {
		if strings.HasPrefix(pp, ":") {
			params[pp[1:]] = pathParts[i]
		} else if pp != pathParts[i] {
			return nil
		}
	}
	return params
}

func (rt *Router) ServeHTTP(w http.ResponseWriter, r *http.Request) {
	path := r.URL.Path

	handler, params := rt.match(r.Method, path)
	if handler == nil {
		http.NotFound(w, r)
		return
	}

	if params != nil {
		q := r.URL.Query()
		for k, v := range params {
			q.Set(k, v)
		}
		r.URL.RawQuery = q.Encode()
	}

	if rt.middleware != nil {
		handler = rt.middleware(http.HandlerFunc(handler)).ServeHTTP
	}

	handler(w, r)
}
