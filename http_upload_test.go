package httpupload

import (
	"bytes"
	"net/http"
	"net/http/httptest"
	"os"
	"path/filepath"
	"testing"

	"github.com/caddyserver/caddy/v2/modules/caddyhttp"
	"github.com/stretchr/testify/assert"
)

func TestServeHTTP(t *testing.T) {
	// Prepare the HTTPUpload instance
	dir := t.TempDir()
	upload := HTTPUpload{
		UploadDir: dir,
	}

	// Prepare the request
	req := httptest.NewRequest(http.MethodPut, "/myfile.txt", bytes.NewBufferString("Hello World"))
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
	assert.Contains(t, rr.Body.String(), expectedPath)

	// Assert that the file was created
	_, err = os.Stat(expectedPath)
	assert.NoError(t, err)
}
