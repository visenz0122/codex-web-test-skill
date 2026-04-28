# Form Input Type

## Applicable Scope

Any "fill form + submit" pattern:

- Login, registration, password reset
- Submit information, application, questionnaire, feedback form
- Create resource (create account, create order, publish article)
- Settings / configuration functionality (change notification preference, change password)

**Key distinguishing factor**: one or more input fields, user fills them and triggers system behavior through "submit" action.
Single operation, not multi-step workflow.

## Mandatory Checklist

### Field-Level Input

- **Equivalence class of each field**: valid input (possibly multiple classes) + various invalid input (empty, too long, wrong format, special characters)
- **Boundary value of each field**: length upper/lower limit, numerical upper/lower limit, character set boundary
- **Cross-field constraint**: combination validation of field A and B (such as when country=US zipCode must be filled)

### Client vs Server

- **Is client validation independently valid**: can server still reject after deleting frontend validation code?
- **Bypass client validation and submit directly**: use API call, submit after modifying DOM, use curl to send request directly
- **Are error prompts consistent**: do client error text and server error text correspond

### Security Related

- **CSRF / token validation**: forge token, use expired token, submit without token
- **Special character injection**: SQL injection characteristic characters, XSS payload, Markdown injection, zero-width character, URL injection
- **HTML tag input**: is `<script>` / `<img onerror=...>` escaped

### Submit Behavior

- **Prevent double submission**: repeatedly click submit button, API replay, auto-retry after network reconnection
- **Submitting state**: button grayed out, loading display, prevent double-send

### User Experience

- **Save draft / leave midway** (when this feature exists): unsaved prompt, auto-save recovery
- **After submit success**: jump target, clear form, display success prompt

## Key Reminders

**Absolutely do not treat "client validation" as complete validation**. Client can only improve user experience, cannot serve as security barrier—
any security-related input validation must be independently tested on server side.

**Do not combine multiple invalid reasons into one TC**. For example "@@@" violates both "no @" and "multiple @" rules at same time,
failure cause is unclear, should split into two TCs each only violating one rule.

## Not Applicable Cases

- Multi-step workflow (such as multi-step order checkout) → use "user journey / Use Case Testing" methodology
- Dialog-style input (although also has input field) → use "dialog-style UI" pattern
- File upload main → use "file upload / download" pattern
