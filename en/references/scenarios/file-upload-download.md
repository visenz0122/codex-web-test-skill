# File Upload / Download

## Applicable Scope

Any functionality involving file input or file output:

- Avatar / image upload
- Document upload (PDF / Word / Excel)
- Video / audio upload
- Batch file upload
- File download (export report, download attachment)
- Drag-drop upload
- Screenshot paste upload

**Key distinguishing factor**: user-submitted input or obtained output involves "binary file",
not just text data.

## Mandatory Checklist (Upload)

### Five Dimensions of Boundary

See `methodologies/boundary-value-analysis.md` end section "boundaries of multimodal input", five dimensions:

#### 1. Size Dimension
- 0 bytes (empty file)
- 1 byte (minimum non-empty)
- System allowed maximum
- Exceed maximum by 1 byte
- Extreme large value (test DoS protection)

#### 2. Format Dimension
- Each supported format representative
- Unsupported format
- **Disguised format** (file extension and actual content mismatch)—this is key security test point

#### 3. Content Dimension
- Blank content (all-white image, empty PDF)
- Minimal content
- Extremely complex content
- Containing sensitive data (image contains face, document contains credit card)
- **Containing malicious payload** (XSS in SVG, JS in PDF, ZIP bomb)

#### 4. Metadata Dimension
- No EXIF metadata
- Contains GPS coordinates (privacy)
- Special characters in filename (such as `../../../etc/passwd.png` test path traversal)

#### 5. Damaged / Abnormal Dimension
- Truncated file
- Header corrupted
- Nested compression bomb

### Upload Process

- **Upload progress display**: is progress bar accurate
- **Cancel upload**: cancel during progress, does backend clean up received partial
- **Upload failure retry**: can resume from breakpoint
- **Concurrent upload multiple files**: not interfere, overall progress display
- **Upload under slow network**: timeout setting, user experience

### Server-Side Validation

- **Server re-validate**: not rely on client "looks OK"
- **Virus scan** (if any): scan after upload
- **Storage path safety**: uploaded file cannot store in system sensitive directory
- **Filename rewriting**: does server generate safe filename (not directly use user-supplied)

## Mandatory Checklist (Download)

### Basics

- **Normal download**: file correctly generated, Content-Type correct, filename encoding correct (Chinese filename)
- **Unauthorized download**: can download other people's file, file should not be public
- **File does not exist**: return 404 not 500
- **Large file download**: resume capability (if any), transmission interruption handling

### Streaming vs Full

- **Streaming download** (generate while sending): how to handle error midway
- **Full download** (send only after all generated): wait time for large file, timeout

### Security

- **Path traversal**: is `../` in URL or parameter correctly handled
- **Filename injection**: is filename in Content-Disposition safe
- **Direct URL access**: can directly download without authentication by guessing URL

## Key Reminders

**Disguised format** is most commonly overlooked security test in file upload. Code uses file extension to determine file type + doesn't validate magic number,
directly bypassed. Each upload functionality should test ".png extension but actually .exe".

**Under Browser Use, file download usually cannot validate file content**—can only validate download URL and HTTP header.
In this case Cartographer phase 2 should identify tool capability, mark "download content validation" as manual_upload or adjust test method.

**Test file preparation strategy** (see cartographer.md phase 2.5):
- A. User-specified path (existing fixture)
- B. Manual upload at runtime (user manually operate during test)
- C. Agent generate (temporarily generate simple file, has capability boundary)

**Note Agent generate capability boundary**: can generate simple image, corrupted file, disguised file, solid color block,
but cannot generate "real facial photo" etc. content that needs real data.

## Common Overlaps

Usually appears together with these patterns:
- Form input type (file as one of form fields)
- Multi-tenant / permission matrix (who can upload who can download)
- Async / streaming output (upload / download progress)
- CRUD list and detail (file as resource being managed)
