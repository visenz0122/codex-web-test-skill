# Exception Paths (Universal)

## Applicable Scope

**Almost all non-pure-static functionality should match this pattern**—exception paths are universal, not specific to any business,
but are most commonly overlooked category of tests.

Very few inapplicable scenarios, only:

- Pure static display page (no server interaction)
- Pure frontend component (tab switching, tooltip)

## Mandatory Checklist

### Network Exception

- **Network disconnected during request**: does UI have prompt, can retry
- **Slow network** (each segment has large delay): loading state, timeout setting
- **Network jitter**: connection breaks then recovers, can functionality continue
- **Complete offline**: experience in offline mode
- **Proxy / VPN causing strange behavior**: some proxies modify HTTP headers, buffer responses

### Server Exception

- **HTTP 5xx**: 500 / 502 / 503 / 504, does frontend gracefully degrade
- **HTTP 4xx**: 400 (request format error), 401 (unauthenticated), 403 (no permission), 404, 409 (conflict), 429 (rate limiting)
- **Unexpected response format**: JSON parsing failure, empty response, HTML instead of JSON
- **Response field missing**: expected field does not exist
- **Response field type wrong**: expect number actually string

### Resource Exhaustion

- **Rate limiting triggered** (429): user / IP / interface / global rate limiting
- **Quota exceeded**: user reached limit (storage, API calls, record count)
- **Disk full / out of memory**: server-side resource exhaustion
- **Database connection pool full**: concurrent requests exceed pool size

### Data Exception

- **Concurrent modification conflict** (409): optimistic locking failure, version mismatch
- **Unique constraint violated**: duplicate insert
- **Foreign key constraint violated**: reference non-existent resource
- **Data type mismatch**

### Third-Party Dependency Failure

- **Email service down**: verification email send failure how to handle
- **Payment gateway timeout / failure**: order status how to handle (hang? rollback?)
- **External API failure**: such as calling map API, calling LLM API, calling OAuth provider
- **CDN failure**: static resource load failure, can UI gracefully degrade
- **Third-party service slow**: timeout, retry, degradation strategy

### Timeout

- **Request timeout**: frontend fetch timeout, backend call downstream timeout
- **Long task timeout**: scheduled task, async task timeout
- **Session timeout midway**: user operating midway when session expires

### Browser / Client Environment

- **Browser tab frozen** (background tab)
- **Local storage full** (localStorage / cookie quota)
- **Cross-browser difference** (if cross-browser support needed)

### Authentication Invalidation Midway

- **Session expires midway**: user operating midway when session expires, experience how
- **Token refresh failure**: refresh token also expired
- **User kicked offline then operate**: how to prompt

## Key Reminders

**"Exception paths completely not tested" is most common P0 missed test**—developers tend to have "happy path bias",
exception paths if not forcibly reminded, almost certainly will be overlooked.

**All functionality (except pure static) should at least match several items of this pattern**—
don't need to test all, but **at least** test:
- Network disconnection
- Backend 5xx
- Input validation failure server response

**Tool support for simulating exceptions**:
- Playwright supports offline / route mock / status code injection, fully support various exception simulation
- Browser Use has limited support—usually can only wait for real exception to occur
- If tool doesn't support, should mark ⚠ in self-check table + tool capability rationale

## Common Overlaps

This pattern **almost overlaps with all other patterns**—any main path pattern should be accompanied by exception path pattern.

Particularly note:
- **Login functionality**: wrong password, rate limiting, CAPTCHA failure, account locked
- **Payment functionality**: payment gateway timeout, callback failure, concurrent payment
- **File upload**: file too large, wrong format, network disconnection
- **LLM agent**: LLM service down, timeout, rate limiting
