package main

import (
	"fmt"
	"log"
	"net/http"

	"github.com/Gylmynnn/declient/be/internal/config"
	"github.com/Gylmynnn/declient/be/internal/handler"
	"github.com/Gylmynnn/declient/be/internal/repository"
	"github.com/Gylmynnn/declient/be/internal/router"
	"github.com/Gylmynnn/declient/be/internal/service"
)

func corsMiddleware(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Access-Control-Allow-Origin", "*")
		w.Header().Set("Access-Control-Allow-Methods", "GET, POST, PUT, PATCH, DELETE, OPTIONS")
		w.Header().Set("Access-Control-Allow-Headers", "Content-Type, Authorization")

		if r.Method == http.MethodOptions {
			w.WriteHeader(http.StatusOK)
			return
		}

		next.ServeHTTP(w, r)
	})
}

func main() {
	cfg := config.Load()

	collectionRepo := repository.NewFileCollectionRepository(cfg.DataDir)
	folderRepo := repository.NewFileFolderRepository(cfg.DataDir)
	requestRepo := repository.NewFileRequestRepository(cfg.DataDir)
	environmentRepo := repository.NewFileEnvironmentRepository(cfg.DataDir)
	historyRepo := repository.NewFileHistoryRepository(cfg.DataDir)
	metaRepo := repository.NewFileMetaRepository(cfg.DataDir)

	collectionService := service.NewCollectionService(collectionRepo, folderRepo, requestRepo)
	folderService := service.NewFolderService(collectionRepo, folderRepo, requestRepo)
	requestService := service.NewRequestService(requestRepo, environmentRepo, metaRepo, historyRepo)
	environmentService := service.NewEnvironmentService(environmentRepo, metaRepo)
	historyService := service.NewHistoryService(historyRepo)
	transferService := service.NewTransferService(collectionRepo, folderRepo, requestRepo, environmentRepo)

	collectionHandler := handler.NewCollectionHandler(collectionService, folderService, requestService)
	folderHandler := handler.NewFolderHandler(folderService)
	requestHandler := handler.NewRequestHandler(requestService)
	environmentHandler := handler.NewEnvironmentHandler(environmentService)
	historyHandler := handler.NewHistoryHandler(historyService)
	transferHandler := handler.NewTransferHandler(transferService)

	r := router.New()
	r.Use(corsMiddleware)

	// Health
	r.GET("/api/health", func(w http.ResponseWriter, req *http.Request) {
		w.Header().Set("Content-Type", "application/json")
		_, _ = w.Write([]byte(`{"status":"ok","app":"declient"}`))
	})

	// Collections
	r.GET("/api/collections", func(w http.ResponseWriter, req *http.Request) {
		collectionHandler.GetAll(w, req)
	})
	r.POST("/api/collections", func(w http.ResponseWriter, req *http.Request) {
		collectionHandler.Create(w, req)
	})
	r.GET("/api/collections/:id", func(w http.ResponseWriter, req *http.Request) {
		collectionHandler.GetByID(w, req)
	})
	r.PUT("/api/collections/:id", func(w http.ResponseWriter, req *http.Request) {
		collectionHandler.Update(w, req, req.URL.Query().Get("id"))
	})
	r.DELETE("/api/collections/:id", func(w http.ResponseWriter, req *http.Request) {
		collectionHandler.Delete(w, req, req.URL.Query().Get("id"))
	})

	// Folders
	r.GET("/api/collections/:id/folders", func(w http.ResponseWriter, req *http.Request) {
		folderHandler.GetByCollection(w, req)
	})
	r.POST("/api/collections/:id/folders", func(w http.ResponseWriter, req *http.Request) {
		folderHandler.Create(w, req)
	})
	r.POST("/api/folders", func(w http.ResponseWriter, req *http.Request) {
		folderHandler.Create(w, req)
	})
	r.PUT("/api/folders/:id", func(w http.ResponseWriter, req *http.Request) {
		folderHandler.Update(w, req, req.URL.Query().Get("id"))
	})
	r.DELETE("/api/folders/:id", func(w http.ResponseWriter, req *http.Request) {
		folderHandler.Delete(w, req, req.URL.Query().Get("id"))
	})

	// Requests
	r.GET("/api/collections/:id/requests", func(w http.ResponseWriter, req *http.Request) {
		requestHandler.GetByCollection(w, req)
	})
	r.POST("/api/collections/:id/requests", func(w http.ResponseWriter, req *http.Request) {
		requestHandler.Create(w, req)
	})
	r.POST("/api/requests", func(w http.ResponseWriter, req *http.Request) {
		requestHandler.Create(w, req)
	})
	r.GET("/api/requests/:id", func(w http.ResponseWriter, req *http.Request) {
		requestHandler.GetByID(w, req, req.URL.Query().Get("id"))
	})
	r.PUT("/api/requests/:id", func(w http.ResponseWriter, req *http.Request) {
		requestHandler.Update(w, req, req.URL.Query().Get("id"))
	})
	r.DELETE("/api/requests/:id", func(w http.ResponseWriter, req *http.Request) {
		requestHandler.Delete(w, req, req.URL.Query().Get("id"))
	})
	r.POST("/api/requests/:id/send", func(w http.ResponseWriter, req *http.Request) {
		requestHandler.Send(w, req, req.URL.Query().Get("id"))
	})
	r.POST("/api/send", func(w http.ResponseWriter, req *http.Request) {
		requestHandler.SendAdhoc(w, req)
	})

	// Environments
	r.GET("/api/environments", func(w http.ResponseWriter, req *http.Request) {
		environmentHandler.GetAll(w, req)
	})
	r.POST("/api/environments", func(w http.ResponseWriter, req *http.Request) {
		environmentHandler.Create(w, req)
	})
	r.GET("/api/environments/active", func(w http.ResponseWriter, req *http.Request) {
		environmentHandler.GetActive(w, req)
	})
	r.POST("/api/environments/active", func(w http.ResponseWriter, req *http.Request) {
		environmentHandler.SetActive(w, req, "")
	})
	r.GET("/api/environments/:id", func(w http.ResponseWriter, req *http.Request) {
		environmentHandler.GetByID(w, req, req.URL.Query().Get("id"))
	})
	r.PUT("/api/environments/:id", func(w http.ResponseWriter, req *http.Request) {
		environmentHandler.Update(w, req, req.URL.Query().Get("id"))
	})
	r.DELETE("/api/environments/:id", func(w http.ResponseWriter, req *http.Request) {
		environmentHandler.Delete(w, req, req.URL.Query().Get("id"))
	})
	r.POST("/api/environments/:id/activate", func(w http.ResponseWriter, req *http.Request) {
		environmentHandler.SetActive(w, req, req.URL.Query().Get("id"))
	})
	r.POST("/api/resolve", func(w http.ResponseWriter, req *http.Request) {
		environmentHandler.Resolve(w, req)
	})

	// History
	r.GET("/api/history", func(w http.ResponseWriter, req *http.Request) {
		historyHandler.GetAll(w, req)
	})
	r.DELETE("/api/history", func(w http.ResponseWriter, req *http.Request) {
		historyHandler.Clear(w, req)
	})
	r.DELETE("/api/history/:id", func(w http.ResponseWriter, req *http.Request) {
		historyHandler.Delete(w, req, req.URL.Query().Get("id"))
	})

	// Import / Export
	r.GET("/api/export", func(w http.ResponseWriter, req *http.Request) {
		transferHandler.Export(w, req)
	})
	r.POST("/api/import", func(w http.ResponseWriter, req *http.Request) {
		transferHandler.Import(w, req)
	})
	r.POST("/api/import/native", func(w http.ResponseWriter, req *http.Request) {
		transferHandler.ImportNative(w, req)
	})

	addr := fmt.Sprintf(":%s", cfg.Port)
	fmt.Printf("DeClient backend running on http://localhost%s\n", addr)
	fmt.Printf("Data directory: %s\n", cfg.DataDir)

	log.Fatal(http.ListenAndServe(addr, r))
}
