package main

import (
	"context"
	"fmt"
	"io"
	"log"
	"net/http"

	"github.com/aws/aws-sdk-go-v2/aws"
	"github.com/aws/aws-sdk-go-v2/config"
	"github.com/aws/aws-sdk-go-v2/service/s3"
	"github.com/caarlos0/env/v11"
)

type Config struct {
	BucketName string `env:"S3_BUCKET_NAME,required"`
	Port       int    `env:"PORT"                    envDefault:"8080"`
}

func main() {
	cfg := Config{}
	if err := env.Parse(&cfg); err != nil {
		log.Fatalf("Failed to parse environment variables: %v", err)
	}

	awsCfg, err := config.LoadDefaultConfig(context.TODO())
	if err != nil {
		log.Fatalf("Failed to load AWS config: %v", err)
	}

	s3Client := s3.NewFromConfig(awsCfg)

	http.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
		fileName := r.URL.Query().Get("file")
		if fileName == "" {
			fileName = "default.txt" // Default file if no query parameter is provided
		}

		output, err := s3Client.GetObject(context.TODO(), &s3.GetObjectInput{
			Bucket: aws.String(cfg.BucketName),
			Key:    aws.String(fileName),
		})
		if err != nil {
			http.Error(
				w,
				fmt.Sprintf("Failed to get object from S3: %v", err),
				http.StatusInternalServerError,
			)
			return
		}
		defer output.Body.Close()

		w.Header().Set("Content-Type", "text/plain")
		_, err = io.Copy(w, output.Body)
		if err != nil {
			log.Printf("Error writing response: %v", err)
		}

		log.Printf("Successfully retrieved text from %v", fileName)
	})

	log.Printf("Starting server on port %d", cfg.Port)
	if err := http.ListenAndServe(fmt.Sprintf(":%d", cfg.Port), nil); err != nil {
		log.Fatalf("Failed to start server: %v", err)
	}
}
