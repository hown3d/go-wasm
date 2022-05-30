package main

import (
	"fmt"
	"log"
	"net/http"
	"os"
	"path/filepath"
)

func main() {
	wd, err := os.Getwd()
	if err != nil {
		log.Fatal(err)
	}
	fmt.Println(wd)
	fmt.Println("starting out :9090")

	handler := http.FileServer(http.Dir(filepath.Join(wd, "normal-go", "out")))

	err = http.ListenAndServe(":9090", handler)
	if err != nil {
		fmt.Println("Failed to start server", err)
		return
	}
}
