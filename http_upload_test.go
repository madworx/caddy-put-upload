package httpupload

import (
	"bytes"
	"context"
	"net/http"
	"net/http/httptest"
	"os"
	"path/filepath"
	"testing"

	"github.com/caddyserver/caddy/v2"
	"github.com/caddyserver/caddy/v2/caddyconfig/caddyfile"
	"github.com/caddyserver/caddy/v2/caddyconfig/httpcaddyfile"
	"github.com/caddyserver/caddy/v2/modules/caddyhttp"
	"github.com/stretchr/testify/assert"
)

// TestServeHTTP tests the HTTPUpload's ServeHTTP method. It sets up an HTTPUpload instance and a
// PUT request to a temporary file. The test asserts that no error occurs during the HTTP request
// handling, and that the response code, response body, and file creation are as expected.
// If a non-PUT request is received, an HTTP error with status "Method Not Allowed" is expected.
func TestServeHTTP(t *testing.T) {
	// Prepare the HTTPUpload instance
	dir := t.TempDir()
	upload := HTTPUpload{
		UploadDir: dir,
	}

	// Prepare the request
	req := httptest.NewRequest(http.MethodPut, "/myfile.txt", bytes.NewBufferString("Hello World"))
	repl := caddyhttp.NewTestReplacer(req)
	ctx := context.WithValue(req.Context(), caddy.ReplacerCtxKey, repl)
	req = req.WithContext(ctx)
	rr := httptest.NewRecorder()

	// Prepare a dummy next handler
	nextHandler := caddyhttp.HandlerFunc(func(w http.ResponseWriter, r *http.Request) error {
		http.Error(w, "Not a PUT request", http.StatusMethodNotAllowed)
		return nil
	})

	// Call ServeHTTP method
	err := upload.ServeHTTP(rr, req, nextHandler)
	assert.NoError(t, err)

	// Assert the status code
	assert.Equal(t, http.StatusCreated, rr.Code)

	// Assert the response body
	expectedPath := filepath.Join(dir, "myfile.txt")
	assert.Contains(t, rr.Body.String(), "myfile.txt")

	// Assert that the file was created
	_, err = os.Stat(expectedPath)
	assert.NoError(t, err)
}

// TestParseCaddyfile tests the parseCaddyfile function. It sets up a Caddyfile dispenser
// with an http_put_file directive pointing to a temporary directory. The test asserts that
// no error occurs during parsing, and that the resulting middleware handler can be converted
// back to an HTTPUpload instance with the expected upload directory.
func TestParseCaddyfile(t *testing.T) {
	// Arrange
	expected := "/tmp"
	dispenser := caddyfile.NewTestDispenser("http_put_file " + expected + " .")
	helper := httpcaddyfile.Helper{
		Dispenser: dispenser,
	}

	// Act
	middlewareHandler, err := parseCaddyfile(helper)

	// Convert the middlewareHandler back to an HTTPUpload object
	m, ok := middlewareHandler.(HTTPUpload)

	// Assert
	if err != nil {
		t.Fatalf("Unexpected error occurred: %v", err)
	}
	if !ok {
		t.Fatalf("Failed to convert MiddlewareHandler to HTTPUpload")
	}
	if m.UploadDir != expected {
		t.Errorf("Expected '%s', but got '%s'", expected, m.UploadDir)
	}
}
