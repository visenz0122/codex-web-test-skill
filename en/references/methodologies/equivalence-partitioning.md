# Equivalence Partitioning

## Core Concept

Partition all possible values of an input field into several "equivalence classes".
Within each equivalence class, any value should produce the same system behavior.
**When testing, only one representative value from each class is needed** — this is the core savings.

If a class's representative value passes/fails, you can infer all values in that class should have the same result.

## Partitioning Principles

1. **Valid inputs form one or more classes**
   - If valid inputs have different subtypes (e.g. admin / regular user), each subtype is one class
2. **Each type of invalid input forms one class**
   - Different invalid reasons (empty, too long, wrong format, injection) each get a class, **cannot merge**
   - Merging makes it impossible to tell which cause led to failure
3. **Boundaries are not equivalence classes**
   - Boundary values handled separately by Boundary Value Analysis

## Application Steps (for Inspector)

After receiving test cases, Inspector checks each **input field** as follows:

1. List all possible equivalence classes for this field
2. Check each class has at least one corresponding test case
3. Check invalid input classes are not merged (common error)
4. Output P0/P1/P2 level feedback

## Example: Email field in login

**Valid input classes**:
- Registered email (corresponds to B1)
- Unregistered email (corresponds to B2)

**Invalid input classes** (each tested separately):
- Empty string
- String without @ ("foobar")
- String with multiple @ ("a@b@c.com")
- Too long email (>254 chars, violates RFC 5321)
- Email with Chinese characters
- Email with special injection characters ("'; DROP TABLE--@x.com")

→ At least 8 test cases. Fewer than 8 means some class uncovered.

## Inspector Feedback Example

```
P0-001: email field missing test case for "unregistered email" class
- Methodology: Equivalence Partitioning
- Issue: test cases only test registered email, but spec B2 explicitly requires unregistered scenario
- Suggested fix: add TC with non-existent database email, expected should match B2

P1-001: invalid email classes merged
- Methodology: Equivalence Partitioning
- Issue: TC-005 uses "@@@" violating both "no @" and "multiple @" rules, failure attribution unclear
- Suggested fix: split into two TCs, each violating only one rule
```

## Common Mistakes

- ❌ merge all "invalid inputs" into one class
- ❌ miss subtype of valid input (e.g. admin user)
- ❌ use Boundary instead of Equivalence (EP tests representative, BVA tests boundaries, different responsibilities)
- ❌ list more than one representative value per class (waste, EP's essence is "one is enough")
