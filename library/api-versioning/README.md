# API Versioning SOP

SOP for managing breaking API changes without breaking existing consumers.

## When to Use

Apply this SOP when making any of the following changes to an API:

- Changing endpoint signatures (path, method, required parameters)
- Removing an endpoint
- Changing response shapes (removing fields, renaming fields, changing types)
- Renaming fields in request or response bodies
- Changing authentication or authorization requirements
- Changing error response formats

## Steps

### 1. Identify the Breaking Change

Before implementing, document:

- **What is changing**: the specific endpoint(s) and fields affected
- **Why it is changing**: the reason for the break (new data model, security fix, simplification)
- **Who consumes it**: list all known consumers (internal apps, external integrations, SDKs, other services)

### 2. Internal Consumers Only

If all consumers are within the same codebase or controlled by the same team:

1. Update the API and all consumers in the same PR
2. Add `BREAKING CHANGE:` to the commit message body with a description of what changed
3. Update any API documentation or type definitions
4. No versioning overhead needed — coordinate the change atomically

### 3. External Consumers Exist

If the API has consumers you do not control (external integrations, published SDKs, third-party apps):

#### a. Add API Version Support

Choose a versioning strategy and implement it:

- **URL prefix** (most common): `/api/v1/resource` -> `/api/v2/resource`
- **Header-based**: `API-Version: 2` or `Accept: application/vnd.app.v2+json`
- **Query parameter**: `/api/resource?version=2`

The old version continues to work unchanged. The new version contains the breaking change.

#### b. Deprecation Period

1. Mark the old version as deprecated in documentation and response headers (`Deprecation: true`, `Sunset: <date>`)
2. Set a deprecation timeline (typically 3-6 months, adjust based on consumer needs)
3. Log usage of deprecated endpoints to track migration progress

#### c. Communicate to Consumers

Notify consumers through available channels:

- Changelog or release notes
- API documentation updates
- Direct communication (email, tickets) for known integrators
- Deprecation warnings in API responses

#### d. Remove Old Version

After the deprecation period:

1. Verify no significant traffic on the old version (check logs)
2. Remove the old version code
3. Update documentation to reflect only the current version
4. Announce the removal in release notes

### 4. Commit and Document

For all breaking changes:

- Add `BREAKING CHANGE:` to the commit message body:
  ```
  feat(api): redesign user endpoint response

  BREAKING CHANGE: GET /api/users/:id response shape changed.
  `full_name` split into `first_name` and `last_name`.
  `role` renamed to `roles` (now an array).
  ```
- Update release notes or changelog
- Update API documentation (OpenAPI spec, docs site, SDK types)

### 5. Update API Documentation

Ensure all of the following are updated:

- OpenAPI / Swagger specification (if used)
- API reference documentation
- SDK type definitions
- Example requests/responses in docs
- Postman collections or similar (if maintained)

## Non-Breaking Changes (No Versioning Needed)

The following changes are typically safe and do not require versioning:

- Adding new optional fields to request bodies
- Adding new fields to response bodies (additive)
- Adding new endpoints
- Adding new optional query parameters
- Relaxing validation (accepting more input than before)

## Expected Output

- Breaking change deployed without breaking existing consumers
- All consumers updated (internal) or given deprecation timeline (external)
- Change documented in commit message with `BREAKING CHANGE:` prefix
- API documentation updated
- Changelog or release notes updated
