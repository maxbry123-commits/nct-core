---
description: Guidelines for designing robust, scalable, and intuitive APIs.
---
# API Design Principles

Design APIs that are easy to use and hard to misuse.

## RESTful Standards
- **Resources**: Nouns, plural (e.g., `/users`, `/articles`).
- **Methods**: GET (read), POST (create), PUT/PATCH (update), DELETE (remove).
- **Status Codes**: 
  - 200 OK, 201 Created
  - 400 Bad Request, 401 Unauthorized, 403 Forbidden, 404 Not Found
  - 500 Server Error

## Data Format
- **JSON**: Standard response format.
- **Snake Case**: `user_id`, `created_at` (or camelCase if project standard).
- **Pagination**: `page`, `limit` or cursor-based.
- **Filtering/Sorting**: Query parameters.
