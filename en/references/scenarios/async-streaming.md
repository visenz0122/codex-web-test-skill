# Async / Streaming Output

## Applicable Scope

Any "initiate request → wait → gradually appear" functionality:

- SSE (Server-Sent Events) streaming response
- WebSocket push
- Long polling
- Streaming LLM output (character-by-character / token-by-token rendering)
- File upload progress / download progress
- Background task progress display
- Real-time notification / push

**Key distinguishing factor**: response is not a single complete return, but arrives in multiple steps or gradually.

## Mandatory Checklist

### Timeout and Escape (hard requirement)

**Every wait step must have timeout and escape condition—never allow "waiting indefinitely"**.

- Maximum wait time for streaming output (e.g., 60s)
- "Heartbeat timeout" for no new content during waiting (e.g., no new data for consecutive 10s)
- Handling after timeout: error report, prompt for retry, close connection

### Normal Flow

- Initiate → receive (multiple times) → complete end → subsequent state correct
- Stream "start signal" (e.g., SSE connection event)
- Stream "end signal" (e.g., SSE [DONE] or close event)
- Whether stream content concatenation is correct (concatenate by token / chunk into complete result)

### Early Cancellation

- **User proactively cancels**: click cancel button, close dialog, navigate away from page
- **Does backend stop immediately after cancellation**: should not continue wasting computation resources
- **How to handle received content after cancellation**: retain or clear (depends on business logic)

### Network Exception Handling

- **Network disconnection**: whether to error / auto-reconnect / buffer received content
- **Network jitter**: connection breaks then recovers, can it resume
- **Slow network**: each segment has large delay, does UI display progress normally
- **Proxy / VPN interrupts streaming connection**: many enterprise networks buffer complete response before sending, streaming is actually not streaming

### Tab Behavior

- **Does switching away from tab pause receiving**: browser throttle behavior
- **Can resuming tab restore receiving**: can it display content that occurred but wasn't seen
- **Resource consumption of background tab continuous receiving**

### Concurrent Requests

- **Initiate two streaming requests simultaneously**: do they not interfere with each other
- **Initiate new one before previous completes**: is old one correctly cancelled, is state clear
- **Request race condition**: slow request and fast request concurrent, which result is displayed

### Error Recovery

- **Error mid-stream** (backend 500): graceful degradation, display received partial content + error prompt
- **Error when partial content already received**: is received part retained / displayed
- **Retry mechanism** (if exists): resume from breakpoint / or restart from beginning

### Resource Cleanup

- **After cancellation, is backend connection / computation resource released**
- **Long time without response**: whether to trigger heartbeat keep-alive, or just let it hang
- **Client-side memory**: does long streaming output cause frontend memory leak

## Key Reminders

**Expected in async scenarios must express final stable state using "eventually", cannot write "immediately"**.
All wait steps must explicitly give timeout—this is a hard requirement at design level, cannot be omitted.

**Infinite loop trap**: if test case writes "wait draft → click confirm → wait reasoning reply", but doesn't write timeout and escape condition,
when LLM doesn't produce expected content in this round, Operator will keep waiting → infinite loop.

**Simulating network exceptions** is very difficult under some test tools—Browser Use usually cannot precisely simulate "network disconnection".
If test case needs to test this, usually requires Playwright + offline mode, or mark manual_upload.

## Common Overlaps

Usually appears together with these patterns:
- Dialog-style UI (almost always)
- LLM agent decision (LLM output is almost always streaming)
- File upload / download (upload / download progress is also async)
