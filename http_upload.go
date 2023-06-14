package httpupload

import (
	"fmt"
	"io"
	"net/http"
	"os"
	"path/filepath"
	"strings"

	"github.com/caddyserver/caddy/v2"
	"github.com/caddyserver/caddy/v2/caddyconfig/caddyfile"
	"github.com/caddyserver/caddy/v2/caddyconfig/httpcaddyfile"
	"github.com/caddyserver/caddy/v2/modules/caddyhttp"
)

func init() {
	caddy.RegisterModule(HTTPUpload{})
	httpcaddyfile.RegisterHandlerDirective("http_put_file", parseCaddyfile)
}

type HTTPUpload struct {
	UploadDir string `json:"upload_dir,omitempty"`
}

func (HTTPUpload) CaddyModule() caddy.ModuleInfo {
	return caddy.ModuleInfo{
		ID:  "http.handlers.http_put",
		New: func() caddy.Module { return new(HTTPUpload) },
	}
}

func (h HTTPUpload) ServeHTTP(w http.ResponseWriter, r *http.Request, next caddyhttp.Handler) error {
	if r.Method != http.MethodPut {
		return next.ServeHTTP(w, r)
	}

	defer r.Body.Close()

	uploadPath := filepath.Join(h.UploadDir, strings.TrimPrefix(r.URL.Path, "/"))

	if !strings.HasPrefix(uploadPath, h.UploadDir) {
		return fmt.Errorf("cannot write to path outside of the upload directory")
	}

	err := os.MkdirAll(filepath.Dir(uploadPath), os.ModePerm)
	if err != nil {
		return fmt.Errorf("unable to create directories: %w", err)
	}

	tempFile, err := os.CreateTemp(filepath.Dir(uploadPath), ".upload-*")
	if err != nil {
		return fmt.Errorf("unable to create temp file: %w", err)
	}
	defer os.Remove(tempFile.Name()) // clean up in case of failure

	if _, err = io.Copy(tempFile, r.Body); err != nil {
		return fmt.Errorf("unable to write file: %w", err)
	}

	if err = tempFile.Close(); err != nil {
		return fmt.Errorf("unable to close temp file: %w", err)
	}

	// Rename the temp file to the desired name, overwriting if file already exists
	if err = os.Rename(tempFile.Name(), uploadPath); err != nil {
		return fmt.Errorf("unable to rename temp file: %w", err)
	}

	w.WriteHeader(http.StatusCreated)
	if _, err := w.Write([]byte(fmt.Sprintf("File %s created successfully", uploadPath))); err != nil {
		return fmt.Errorf("unable to write response: %w", err)
	}

	return nil
}

func (h *HTTPUpload) UnmarshalCaddyfile(d *caddyfile.Dispenser) error {
	for d.Next() {
		args := d.RemainingArgs()
		if len(args) != 1 {
			return d.ArgErr()
		}
		h.UploadDir = args[0]
	}
	return nil
}

func parseCaddyfile(h httpcaddyfile.Helper) (caddyhttp.MiddlewareHandler, error) {
	var m HTTPUpload
	err := m.UnmarshalCaddyfile(h.Dispenser)
	if err != nil {
		return nil, err
	}
	return m, nil
}
