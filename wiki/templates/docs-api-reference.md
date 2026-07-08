---
tags: [docs, <project>, api-reference]
date: YYYY-MM-DD
type: documentation
category: docs
aliases: []
sources: []
related: [<entity pages in wiki/entities/>]
---

# API Reference — <Project/Framework Name>

<!-- Navigation header — ALWAYS at top -->
[← Previous Topic](../docs/<prev-topic>.md) · [Back to Index](../docs-index.md) · [Next Topic →](<next-topic>.md)

---

## Overview

Brief paragraph defining the scope of this API reference. What does it cover? What's out of scope?

<!-- EXAMPLE: The Symfony Messenger Component provides a robust messaging system that allows messages to be sent through "transport" channels. This reference covers all transport components, message handlers, and routing configuration options. -->

## Prerequisites

- **Runtime version**: `<minimum_version>`
- **Dependencies**: `<required_packages>`
- **Environment**: `<OS/DB requirements>`

<!-- EXAMPLE: PHP >= 8.0, Symfony Flex installed, Composer dependencies configured -->

---

## API Reference

### <Resource Group Name>

<Description of what this resource group does>

#### `POST /<endpoint>`

Create a new <resource>.

**Request body:**
```json
{
  "field_name": "<type_example>",
  "another_field": "<type_example>"
}
```

**Response (201 Created):**
```json
{
  "id": "<string_uuid>",
  "created_at": "<ISO8601_timestamp>",
  ...
}
```

#### `GET /<endpoint>/<id>`

Retrieve a <resource> by ID.

**Response (200 OK):**
```json
{...}
```

<!-- Repeat for each endpoint/resource group -->

---

### Error Codes

| Code | Description | Example Response |
|------|-------------|------------------|
| `400` | Bad request — invalid input format | `{"error": "Field 'x' is required"}` |
| `401` | Unauthorized — missing/invalid credentials | `{"error": "Authentication required"}` |
| `404` | Not found | `{"error": "Resource not found"}` |
| `500` | Internal server error | `{"error": "Database connection failed"}` |

---

### Response Formats

Standard response envelope:
```json
{
  "status": "<success|error>",
  "data": {...},
  "errors": [],
  "meta": {
    "page": 1,
    "per_page": 25,
    "total": 100
  }
}
```

---

## SDK Usage Examples

### <Language> Example

<!-- EXAMPLE: PHP -->
```php
$client = new HttpClient();
$response = $client->post('/api/messages', [
    'body' => 'Hello World',
    'topic' => 'notifications',
]);
echo json_encode($response, JSON_PRETTY_PRINT);
```

### <Language> Example

<!-- Repeat for each supported language/SDK -->

---

## See Also

- **[Entity page 1]** — `[wiki/entities/<entity>.md](../entities/<entity>.md)`
- **[Concept page]** — `[wiki/concepts/<concept>.md](../concepts/<concept>.md)`
- **CLI reference**: `[<tool>-commands.md](<tool>-commands.md)`

<!-- Navigation footer -->
[← Previous Topic](../docs/<prev-topic>.md) · [Back to Index](../docs-index.md) · [Next Topic →](<next-topic>.md)
