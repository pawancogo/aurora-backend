# File & Media Uploads

One reusable upload system (CarrierWave) with a pluggable storage backend chosen
entirely by configuration. No code changes are needed to switch providers.

## Storage providers

Selected via the `STORAGE_PROVIDER` env var:

| Value        | Backend            | Notes                                            |
|--------------|--------------------|--------------------------------------------------|
| `local`      | Disk `public/uploads` | Default (dev/test). No config needed.         |
| `aws`        | AWS S3 (fog)       | Production. Needs AWS creds (below).             |
| `cloudinary` | Cloudinary         | Optional, media-heavy (images/video).            |

Switching is env-only, e.g. `STORAGE_PROVIDER=aws`. The provider's gem
(`fog-aws` / `cloudinary`) is already bundled but loaded lazily, so `local` pays
no cost. The switch lives in [`config/storage_provider.rb`](../config/storage_provider.rb)
and is applied in [`config/initializers/carrierwave.rb`](../config/initializers/carrierwave.rb).

### AWS S3
```
STORAGE_PROVIDER=aws
AWS_ACCESS_KEY_ID=…        # or Rails credentials aws.access_key_id
AWS_SECRET_ACCESS_KEY=…    # or Rails credentials aws.secret_access_key
AWS_REGION=us-east-1
AWS_BUCKET=my-bucket       # or Rails credentials aws.bucket
# optional: AWS_PUBLIC=true, ASSET_HOST=https://cdn.example.com
```

### Cloudinary
```
STORAGE_PROVIDER=cloudinary
CLOUDINARY_URL=cloudinary://<api_key>:<api_secret>@<cloud_name>
```

## Using it

**Mounted on a model** (any file type):
```ruby
class Document < ApplicationRecord
  mount_uploader  :file,        GenericUploader
  mount_uploaders :attachments, GenericUploader   # multiple
end
```

**Standalone** (store a file, get a URL — provider-agnostic):
```ruby
uploader = Media::Upload.new(params[:file], kind: :image).call
uploader.url   # local: /uploads/media/…  |  s3/cloudinary: absolute URL
```

**From the admin UI** — the reusable widget posts to `POST /admin/uploads` and
writes the returned URL into a target field:
```erb
<%= render "admin/ui/uploader", target: "#product_image_urls",
      mode: "append", kind: "image", label: "Upload images", multiple: true %>
```

## Accepted files
`GenericUploader` accepts images, PDFs, documents (doc/docx/txt/rtf),
spreadsheets (csv/xls/xlsx), presentations (ppt/pptx), video, audio, and zip —
guarded by both an extension and a content-type allowlist. The `/admin/uploads`
endpoint additionally restricts to the requested `kind` (image/video) with a size
cap (10 MB image / 200 MB video).

## Extending later (no model/controller/service changes)
- **Thumbnails / image variants** → add `version :thumb do … end` in `GenericUploader`.
- **Cloudinary transforms / video processing** → switch provider + add transform options in the uploader.
- **Background / direct-to-storage uploads, CDN** → set `ASSET_HOST`, or add a Sidekiq job / direct-upload flow around the same uploader.
- **New provider** → add a branch in the initializer + `StorageProvider`.
