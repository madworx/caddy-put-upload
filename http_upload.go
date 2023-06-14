// Package httpupload provides a HTTP handler for Caddy server,
// enabling file uploads using PUT HTTP method.
package httpupload

import (
	"fmt"
	"io"
	"net/http"
	"os"
	"path"
	"path/filepath"
	"strings"

	"github.com/caddyserver/caddy/v2"
	"github.com/caddyserver/caddy/v2/caddyconfig/caddyfile"
	"github.com/caddyserver/caddy/v2/caddyconfig/httpcaddyfile"
	"github.com/caddyserver/caddy/v2/modules/caddyhttp"
	"go.uber.org/zap"
)

// init function registers the HTTPUpload module and the Caddyfile
// handler directive upon package initialization.
func init() {
	caddy.RegisterModule(HTTPUpload{})
	httpcaddyfile.RegisterHandlerDirective("http_put_file", parseCaddyfile)
}

// HTTPUpload is a struct that defines the module for handling HTTP PUT
// requests for file uploads.
type HTTPUpload struct {
	UploadDir   string `json:"upload_dir,omitempty"`
	RoutePrefix string `json:"route_prefix,omitempty"`
}

// CaddyModule provides the module information to Caddy.
// It creates a new HTTPUpload module.
func (HTTPUpload) CaddyModule() caddy.ModuleInfo {
	return caddy.ModuleInfo{
		ID:  "http.handlers.http_put",
		New: func() caddy.Module { return new(HTTPUpload) },
	}
}

func (h HTTPUpload) Provision(ctx caddy.Context) error {
	return nil
}

// ServeHTTP handles the HTTP requests. If it's a PUT request, it
// handles the upload process and writes the file to the defined
// upload directory. If the request method is not PUT, it simply
// calls the next handler in the chain.
func (h HTTPUpload) ServeHTTP(w http.ResponseWriter, r *http.Request, next caddyhttp.Handler) error {
	// Only handle HTTP PUT method
	if r.Method != http.MethodPut {
		return next.ServeHTTP(w, r)
	}

	defer r.Body.Close()

	// Trimming the UploadDir from URL Path and creating the file upload path
	uploadRootPath := filepath.Join(h.UploadDir)
	uploadFilePath := strings.TrimPrefix(path.Clean(r.URL.Path), h.RoutePrefix)
	uploadDiskPath := filepath.Join(uploadRootPath, uploadFilePath)

	logger := caddy.Log().Named("http.handlers.http_put")
	logger.Info("upload information",
		zap.String("r.URL.Path", r.URL.Path),
		zap.String("h.UploadDir", h.UploadDir),
		zap.String("h.RoutePrefix", h.RoutePrefix),
		zap.String("uploadDiskPath", uploadDiskPath),
		zap.String("uploadFilePath", uploadFilePath),
	)

	// Ensuring that the file is not uploaded outside of the defined upload directory
	if !strings.HasPrefix(uploadDiskPath, uploadRootPath) {
		http.Error(w, "Attempting to write to a path outside the defined upload directory", http.StatusForbidden)
		return nil
	}

	err := os.MkdirAll(filepath.Dir(uploadDiskPath), os.ModePerm)
	if err != nil {
		return fmt.Errorf("unable to create directories: %w", err)
	}

	tempFile, err := os.CreateTemp(filepath.Dir(uploadDiskPath), ".upload-*")
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
	if err = os.Rename(tempFile.Name(), uploadDiskPath); err != nil {
		return fmt.Errorf("unable to rename temp file: %w", err)
	}

	w.WriteHeader(http.StatusCreated)
	if _, err := w.Write([]byte(fmt.Sprintf("File %s created successfully.", uploadFilePath))); err != nil {
		return fmt.Errorf("unable to write response: %w", err)
	}

	return nil
}

// UnmarshalCaddyfile reads the Caddyfile configuration into the HTTPUpload struct.
func (h *HTTPUpload) UnmarshalCaddyfile(d *caddyfile.Dispenser) error {
	for d.Next() {
		args := d.RemainingArgs()
		if len(args) != 2 {
			return d.ArgErr()
		}
		h.UploadDir = args[0]
		h.RoutePrefix = args[1]
	}
	return nil
}

// parseCaddyfile is a helper function that unmarshals a Caddyfile configuration into
// an HTTPUpload object and returns it as a MiddlewareHandler.
func parseCaddyfile(h httpcaddyfile.Helper) (caddyhttp.MiddlewareHandler, error) {
	var m HTTPUpload
	err := m.UnmarshalCaddyfile(h.Dispenser)
	if err != nil {
		return nil, err
	}
	return m, nil
}

// Interface guards
var (
	_ caddyhttp.MiddlewareHandler = (*HTTPUpload)(nil)
	_ caddyfile.Unmarshaler       = (*HTTPUpload)(nil)
)
