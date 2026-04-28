# Profile / Profile Management

## Applicable Scope

Read display user profile + edit save functionality:

- Personal profile page (display user information)
- Edit profile (name, email, phone, bio, etc.)
- Avatar upload / change
- Change password
- Notification preference setting
- Privacy setting

**Key distinguishing factor**: **functionality focuses on "user read and modify own data"**.
Usually does not involve other people's data, but may involve other people viewing self.

## Mandatory Checklist

### Profile Reading

- **Logged-in user view own profile** (success path)
- **Profile field complete display**: each field has display
- **Empty field handling**: when user not filled certain field, how UI display (placeholder / hidden / "not filled")

### Profile Editing

- **Each field modify separately**: only change one field, other fields not change
- **Multiple fields modify simultaneously**: submit multiple fields at once
- **Field constraint**: email format, phone format, username uniqueness, length limit
- **Echo after save**: does UI reflect latest value (prevent cache stale)

### Avatar Upload (if any)

- See "file upload / download" scenario pattern details
- Usually involves size, format, dimension limit

### Privacy Field

- **Change password**: require current password, new old password cannot be same
- **Change email**: whether need original email verification, new email verification
- **Change phone**: whether need SMS verification

### Unauthorized Read/Write

- **Read own profile → ✅ success**
- **Read other people's profile**: URL change ID direct access / direct API call, see if rejected
- **Change other people's profile**: same as above, need server-side permission check
- **Public vs private field**: certain fields are public (username, avatar), certain private (email, phone)

### Concurrency and Consistency

- **Same user two tabs modify simultaneously**: will different fields conflict, same field conflict
- **Unsaved leave prompt**: modify field but not save, close page / navigate away whether prompt
- **Save success prompt**: is UI feedback clear
- **Save failure handling**: network down, server 500, concurrent conflict experience

## Key Reminders

**Unauthorized read/write** most easily overlooked—developers usually only test "self view self",
forget test "user A change user B profile". This bug very common in production,
because backend often use user_id passed by frontend rather than session user_id.

**Unsaved leave prompt** easy to overlook—users will lose work progress because.

## Common Overlaps

Usually appears together with these patterns:
- Form input type (each field input validation)
- Multi-tenant / permission matrix (who can view who, who can change who)
- File upload / download (avatar)

## Not Applicable Cases

- Admin manage other users' profile → use "multi-tenant / permission matrix" pattern
- Public profile display to stranger user (such as blog author homepage) → lean toward "CRUD detail" + permission pattern
