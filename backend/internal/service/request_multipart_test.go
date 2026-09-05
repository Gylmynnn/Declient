package service

import (
	"encoding/base64"
	"mime"
	"mime/multipart"
	"strings"
	"testing"

	"github.com/Gylmynnn/declient/be/internal/model"
)

func TestBuildMultipartBodyTextAndFile(t *testing.T) {
	fileBytes := []byte{0x89, 'P', 'N', 'G', 0x0D}
	fields := []model.FormField{
		{Key: "name", Value: "budi {{suffix}}", Type: "text", Enabled: true},
		{Key: "avatar", Type: "file", FileName: "a.png", ContentType: "image/png", FileBase64: base64.StdEncoding.EncodeToString(fileBytes), Enabled: true},
		{Key: "skip", Value: "x", Enabled: false},
		{Key: "", Value: "x", Enabled: true},
	}
	vars := map[string]string{"suffix": "santoso"}

	ct, body, err := buildMultipartBody(fields, vars)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	mt, params, err := mime.ParseMediaType(ct)
	if err != nil || mt != "multipart/form-data" || params["boundary"] == "" {
		t.Fatalf("bad content-type: %q err=%v", ct, err)
	}
	mr := multipart.NewReader(strings.NewReader(string(body)), params["boundary"])
	got := map[string]struct {
		filename string
		ct       string
		data     string
	}{}
	for {
		part, err := mr.NextPart()
		if err != nil {
			break
		}
		buf := make([]byte, 64)
		n, _ := part.Read(buf)
		got[part.FormName()] = struct {
			filename string
			ct       string
			data     string
		}{part.FileName(), part.Header.Get("Content-Type"), string(buf[:n])}
	}
	if got["name"].data != "budi santoso" {
		t.Fatalf("text field not resolved: %+v", got["name"])
	}
	f := got["avatar"]
	if f.filename != "a.png" || f.ct != "image/png" || f.data != string(fileBytes) {
		t.Fatalf("file part wrong: %+v", f)
	}
	if _, ok := got["skip"]; ok {
		t.Fatalf("disabled field should be skipped")
	}
}

func TestBuildMultipartBodyBadBase64(t *testing.T) {
	fields := []model.FormField{
		{Key: "f", Type: "file", FileName: "a.bin", FileBase64: "!!!bukan-base64!!!", Enabled: true},
	}
	if _, _, err := buildMultipartBody(fields, nil); err == nil {
		t.Fatalf("expected base64 error")
	}
}

func TestBuildMultipartBodyEmpty(t *testing.T) {
	ct, body, err := buildMultipartBody(nil, nil)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if !strings.HasPrefix(ct, "multipart/form-data; boundary=") {
		t.Fatalf("bad content-type: %q", ct)
	}
	if len(body) == 0 {
		t.Fatalf("expected closing boundary bytes")
	}
}
