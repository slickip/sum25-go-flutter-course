package main

import (
	"lab03-backend/api"
	"lab03-backend/storage"
	"log"
	"net/http"
	"time"
)

func main() {
	// TODO: Create a new memory storage instance
	// TODO: Create a new API handler with the storage
	// TODO: Setup routes using the handler
	// TODO: Configure server with:
	//   - Address: ":8080"
	//   - Handler: the router
	//   - ReadTimeout: 15 seconds
	//   - WriteTimeout: 15 seconds
	//   - IdleTimeout: 60 seconds
	// TODO: Add logging to show server is starting
	// TODO: Start the server and handle any errors

	storage := storage.NewMemoryStorage()

	handler := api.NewHandler(storage)

	router := handler.SetupRoutes()

	server := &http.Server{
		Addr:         ":8080",
		Handler:      router,
		ReadTimeout:  15 * time.Second,
		WriteTimeout: 5 * time.Second,
		IdleTimeout:  60 * time.Second,
	}

	log.Println("Starting server on :8080...")
	log.Println("API endpoints available at http://localhost:8080/api/")

	if err := server.ListenAndServe(); err != nil {
		log.Fatal("Server failed to start:", err)
	}
}
