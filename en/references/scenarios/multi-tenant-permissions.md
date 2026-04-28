# Multi-Tenant / Permission Matrix

## Applicable Scope

Any system involving "user, role, resource" isolation:

- Multi-role system (admin / user / guest, etc.)
- Multi-tenant SaaS (organization A data tenant B cannot see)
- Permission grouping (department, team, project permission)
- Resource ownership (user can only manage resources they created)
- Shared resource / public resource (clearly accessible part without login required)

**Key distinguishing factor**: **functionality involves "who can do what" judgment**, not just "how functionality itself does".

## Mandatory Checklist

### Role Permission Matrix

**Enumerate** all roles × all operations:

```
Role \ Operation | Read | Write | Delete | Share | Admin
admin            | ✅   | ✅    | ✅     | ✅    | ✅
user             | ✅   | self  | self   | self  | ❌
guest            | ✅   | ❌    | ❌     | ❌    | ❌
```

**Test each ✅ main path** (success). **Test each ❌ rejection path** (return 403 / redirect to login).

Do not only test own role main path—typical developer bias.

### Cross-tenant Isolation

- **Can tenant A user see tenant B resource**: list query, detail access, direct API call
- **Can tenant A user modify tenant B resource**: URL change ID, direct API call
- **Cross-tenant search**: when tenant A searches, does tenant B content leak

### Unauthorized Access Paths

Not just UI layer, all possible unauthorized paths:

- **URL change ID**: `/profile/123` change to `/profile/124` directly access
- **Direct API call**: bypass UI permission check, directly call API
- **Change role field in cookie / localStorage**: change role=user to role=admin
- **Unprotected admin interface**: some developers forget to add permission check for certain admin API
- **Change user_id in request body**: does server trust ID passed by client rather than session

### Privilege Escalation Attack

- **Regular user change role field**: after login through API modify own role, see if rejected
- **Leverage admin function**: can utilize certain admin exposed interface to escalate own permission
- **Race condition**: execute high-permission operation simultaneously when permission being revoked

### Permission Invalidation

- **After user downgraded / role removed**: does old token / old session immediately invalidate
- **Admin revoke user permission**: how to handle in-progress operation of revoked user
- **Role definition change**: after role X no longer have permission Y, does user holding X immediately lose Y

### Shared Resource / Public Resource

- **Unlogged access to public resource**: can normally see
- **Share to someone**: only that person can see, others cannot
- **Cancel share**: cancelled person immediately lose access
- **Share link**: token link expiration, revocation, single use, etc.

## Key Reminders

**Permission matrix is "disaster area" of P0 missed test**—this is most serious security vulnerability type.
Any single ❌ test missing, may become CVE-level unauthorized bug in production.

**Test "rejection" more important than test "success"**. Developers intuitively write happy path,
but security bugs almost all on "should be rejected but was not".

**Do not assume server will definitely validate**—especially backend developer often assume "frontend will filter",
then write "trust client user_id" code. All unauthorized tests must **bypass UI** directly hit API.

## Common Overlaps

Usually appears together with these patterns:
- CRUD list and detail (permission usually acts on CRUD)
- User authentication / session management (permission based on identity)
- Profile / profile management (who can see whose profile)
