# CRUD List and Detail

## Applicable Scope

Resource management types:

- Article / blog / post
- Order / product / inventory
- Task / project / ticket
- Comment / reply
- Schedule / event / reminder
- File / document / folder

**Key distinguishing factor**: functionality revolves around a class of "resource" doing create-read-update-delete.

## Mandatory Checklist

Divided into four blocks by C / R / U / D, plus List (L).

### List

- **Pagination boundaries**: first page, last page, beyond last page (N+1), empty set
- **Filter / search**: each filter field alone + combination + empty query, special character query
- **Sort**: each sortable field ascending + descending + default sort
- **Large dataset** (if business has performance requirements): query response time assertions
- **Unauthorized list**: can view resources should not see (e.g., other tenants, other departments)

### Read

- **Existing resource**: read normally
- **Non-existent resource**: return 404 not 500
- **Deleted resource** (soft delete scenario): return 410 / 404 / display "deleted"
- **Unauthorized read**: other people's resource, different tenant's resource → should return 403 or 404

### Create

- **Normal create**: data complete
- **Required field missing**: each required field missing separately
- **Unique constraint conflict**: same name / same ID already exists
- **Associated resource does not exist**: foreign key referenced non-existent resource
- **Batch create** (if exists): transaction behavior of partial success partial failure
- **Exceeded quota** (if exists): user reached resource count limit

### Update

- **Full update vs partial update** (PUT vs PATCH)
- **Concurrent modification conflict**: optimistic locking, pessimistic locking, last write wins strategy
- **Update deleted resource**: should be rejected
- **Unauthorized update**: update other people's resource → should be rejected
- **Immutable field**: certain fields cannot be modified after creation (e.g., order's created_at)
- **Status-related update restrictions**: certain fields of paid order cannot change

### Delete

- **Normal delete**
- **Delete non-existent resource**: idempotency (404 or 200, depends on API design)
- **Delete already deleted resource** (soft delete scenario)
- **Cascading delete**: when deleting parent resource how to handle child resource (cascade delete / mark orphan / reject delete)
- **Soft delete recovery** (if exists): can restore after delete, is state correct after recovery
- **Unauthorized delete**: other people's resource → should be rejected
- **Batch delete**: transaction behavior of partial success partial failure

## Key Reminders

**Unauthorized operations** are most easily overlooked in CRUD—developers only test "self CRUD self's resource".
Permission testing must **enumerate exhaustively**: [self / other] × [C / R / U / D] = 8 combinations, each must test rejection.

**Soft delete** is a common trap—frontend "cannot see" deleted resource, but direct API call can recover / bypass.
Testing must verify from API layer, not just look at UI.

**Idempotency**—delete non-existent resource, API design has two reasonable choices (404 / 200),
but **must clearly specify in spec**, cannot let Cartographer test randomly.

## Common Overlaps

Usually appears together with these patterns:
- Multi-tenant / permission matrix (almost always)
- State transition (orders etc. resources with state)
- Exception path (universal)
- Form input type (create / update itself is form)
