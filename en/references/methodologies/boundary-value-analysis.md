# Boundary Value Analysis

## Core Concept

Bugs love to hide at boundaries. Did developer write `if (length >= 8)` or `if (length > 8)`?
One character difference is one bug. BVA is specifically designed to test this one-character difference.

**Core rule**: for each field with boundary, test **values on both sides of boundary**.

## Classic "2-value" Rule

For each boundary, test two values:
- Closest value **inside** boundary (should pass)
- Closest value **outside** boundary (should fail)

## Classic "3-value" Rule (stricter)

For each boundary, test three values:
- Closest value **inside** boundary (pass)
- **Exactly** at boundary (pass or fail, depends on spec using ≥ or >)
- Closest value **outside** boundary (fail)

**Inspector defaults to 3-value requirement**, because it can distinguish implementations of "≥ 8" vs "> 8".

## Application Steps (for Inspector)

1. Find all boundary fields from spec hints.boundary_values
2. For each field, confirm coverage of both sides (at least 2-value, ideal 3-value)
3. For fields **not in hints but code may have implicit boundaries**, suggest checking

## Common Boundary Sources

- **Numeric ranges**: password length 8-32, age 18+, price ≥ 0
- **Collection size**: max 100 items in cart, max 10 files
- **Time**: token expires in 24 hours, session timeout 30 minutes
- **Rate**: 3 requests per hour, 100 ops per 10 seconds
- **String**: empty string, single char, maximum length

## Example: Password length 8-32 characters

3-value:
- 7 (just below, should fail)
- 8 (just at, should pass)
- 9 (confirm pass)
- 31 (confirm pass)
- 32 (just at, should pass)
- 33 (just above, should fail)

→ 6 boundary test cases.

If only testing 8 and 32, you miss 7, 9, 31, 33, **one-character-difference bugs slip through**.

## Inspector Feedback Example

```
P0-001: password.length boundary not fully covered
- Methodology: BVA (3-value)
- Issue: test cases only cover 8 and 32, missing 7/9/31/33
- Affected: spec hints.boundary_values explicitly lists [7, 8, 9, 31, 32, 33]
- Suggested fix: add TCs covering 7 (should fail) and 33 (should fail)

P1-001: rate_limit implicit boundary not tested
- Methodology: BVA
- Issue: spec says "3 per hour", but TCs only test 1 and 5, missing boundary of 3rd vs 4th
- Suggested fix: add TC for 3 consecutive requests in 1 hour (should pass) and 4th (should be rate-limited)
```

## Common Mistakes

- ❌ test only one side (test 8 but not 7)
- ❌ use "middle value" instead of boundary (test 20 chars but miss 8 and 32)
- ❌ ignore boundaries beyond numeric (like time, rate boundaries)
- ❌ treat BVA as EP (EP tests representative, BVA tests boundaries, complement not replacement)

---

## Extended: Multi-field Combination Strategy

When multiple independent fields need testing, combinations explode (N boolean fields = 2^N combinations).
This is no longer "testing each field's boundary", but "how to combine values of multiple fields".

### Strategy Selection

| Dimensions | Recommended | Test case count |
|---|---|---|
| ≤ 3 | Full combination (2^N) | 8-27 |
| 4-8 | Pairwise coverage | typically < 20 |
| > 8 | Pairwise + critical full | < 50 |

**Cartographer must state which strategy was chosen in test case document** —
if not stated, Inspector raises P1 requiring declaration.

### Example: 5 boolean fields in registration form

Fields: `emailVerified`, `phoneVerified`, `agreedToToS`, `subscribedNewsletter`, `referralCodeUsed`

- Full combination: 2^5 = 32, too many
- Pairwise coverage: ~6 TCs cover all pairs of field combinations
- Pairwise **cannot guarantee all bugs caught** — only guarantees "any two fields combined", three+ field coupling bugs may still slip

**Pairwise coverage example** (6 TCs):

| TC | emailV | phoneV | ToS | Newsletter | Referral |
|----|--------|--------|-----|-----------|----------|
| 1 | T | T | T | T | T |
| 2 | F | F | T | F | F |
| 3 | T | F | F | T | F |
| 4 | F | T | F | F | T |
| 5 | T | F | T | F | T |
| 6 | F | T | T | T | F |

### Inspector Checkpoints

1. Count independent dimensions in spec (boolean / enum fields)
2. Check what strategy Cartographer used
3. Validate:
   - Claims "pairwise" but test count much less than pairwise minimum → P0
   - Claims "full combination" but count less than 2^N → P0
   - No strategy claimed → P1 require declaration

### Severity Judgment

- **P0**:
  - Claimed strategy doesn't match actual test count
  - Dimensions ≤ 3 but not using full combination (no rationale to abandon it)
- **P1**:
  - Dimensions > 8 but not using pairwise (test explosion)
  - Strategy not declared
- **P2**:
  - Strategy declared but choice debatable

### Not Applicable

- Single-field feature (use basic BVA)
- Fields with strong constraints (e.g. country=US then zipCode required) — Decision Table better

---

## Multi-modal Input Boundaries (file_inputs field)

File input boundaries (images, PDF, documents, audio/video) far more complex than text —
one file has multiple independent "boundary dimensions", each needs separate consideration.

### Five Dimensions

#### 1. Size Dimension

Most common and easiest to test boundaries:

- 0 bytes (empty file)
- 1 byte (minimal non-empty)
- System minimum (if defined)
- System maximum
- Max + 1 byte
- Extreme large (e.g. 100MB+, test system rejects reasonably not crash)

#### 2. Format Dimension

- **Supported formats** (e.g. PNG/JPG/WebP, test 1 each)
- **Unsupported formats** (e.g. BMP, TIFF — per spec, should be rejected)
- **Disguised format**: file extension mismatches actual content
  - `.png` extension but actually .exe binary
  - `.pdf` extension but actually text file
  - **Critical for security testing**, code usually has no explicit check, easy to miss

#### 3. Content Dimension

- **Blank content** (e.g. all-white image, empty PDF)
- **Minimal content** (single pixel, solid color)
- **Complex content** (dense image, multi-page PDF with tables)
- **Sensitive data** (image with faces, document with credit card numbers — test detection)
- **Malicious payload** (XSS in SVG, JS in PDF, zip bomb in ZIP)

#### 4. Metadata Dimension

File metadata is easy for both users and developers to overlook:

- **EXIF metadata** (images):
  - No EXIF
  - Contains GPS coordinates (privacy concern)
  - Contains other sensitive info (camera model, timestamp)
- **File creation / modification time** (some systems validate)
- **Filename special characters** (e.g. `../../../etc/passwd.png` test path traversal)

#### 5. Corruption/Anomaly Dimension

- **Truncated file** (header correct but content incomplete)
- **Corrupted header** (magic number wrong)
- **Nested compression bomb** (zip inside zip, decompresses to thousand times size)
- **Oversized fields** (e.g. super-long string in PDF trigger buffer issues)

### Application Steps (for Inspector)

For each file_inputs field, Inspector checks whether test cases cover:

1. **Size**: at least 0 bytes + max + over-max
2. **Format**: at least 1 supported + 1 unsupported + 1 disguised
3. **Content**: at least 1 normal + 1 anomalous (blank/minimal/malicious pick one)
4. **Corruption**: at least 1 corrupted file

Not requiring all 5 dimensions — trim by spec semantics. But **security boundaries** (disguised format, malicious payload, path traversal)
are P0 requirement, nearly all upload features must test these.

### Inspector Feedback Example

```
P0-001: file upload not tested disguised format
- Methodology: BVA (multi-modal-format dimension)
- Issue: TC only tested normal PNG and unsupported BMP, didn't test ".png extension but actually .exe"
  This is common file upload security vulnerability
- Suggested fix: add TC with filename fake.png but content is non-image binary (e.g. any .exe renamed),
  expected should be rejected (based on magic number check, not extension)

P1-001: size boundary coverage incomplete
- Methodology: BVA (multi-modal-size dimension)
- Issue: spec says "max 5MB", TC only tested 3MB passes, didn't test 5MB (boundary) and 5MB+1byte (over)
- Suggested fix: add TCs covering 5MB (should pass) and 5.001MB (should fail)
```

### Severity Judgment

- **P0**:
  - Security boundaries not tested (disguised format, malicious payload, path traversal)
  - Size upper limit not tested (can lead to service DoS by oversized files)
- **P1**:
  - General size boundaries not tested (e.g. minimum)
  - Corrupted files not tested
- **P2**:
  - Metadata not tested (EXIF etc., usually lower priority)
  - Minimal content not tested

### Common Mistakes

- ❌ only test "happy path" (one normal image) and think you're done
- ❌ confuse "unsupported format" with "disguised format" (test different code paths)
- ❌ miss disguised format (code uses extension check + no magic number validation, easily bypassed)
- ❌ use real malicious files for testing (should use synthetic test payloads, avoid mixing real danger into project)
