# PlantMama API Documentation

Complete API documentation for the PlantMama flower shop platform, supporting web admin dashboards and Flutter mobile applications.

## Documentation Files

### OpenAPI Specification
**File:** `flutter-api-documentation.yaml`

Complete OpenAPI 3.1 specification covering all API endpoints for mobile and web clients. This document includes:

- All endpoint definitions with detailed descriptions
- Request/response schemas with examples
- Authentication and authorization details
- Error codes and handling
- Region support and multi-region operations
- Pagination and filtering parameters
- Complete data models

**Usage:**
- Import into Postman, Insomnia, or other API clients
- Generate SDKs using OpenAPI generators
- Use with Swagger UI or Redoc for interactive documentation
- Reference for integration and API implementation

### Flutter Integration Guide
**File:** `FLUTTER_API_GUIDE.md`

Comprehensive guide for Flutter developers integrating with the PlantMama API. Includes:

- Getting started setup instructions
- JWT authentication and token management
- API client implementation with interceptors
- Common patterns and best practices
- Complete Dart code examples for:
  - Authentication (login, register, logout)
  - Product browsing and search
  - Cart management and validation
  - Order creation and tracking
  - User profile management
  - Address management
- Error handling strategies
- Troubleshooting guide

**Who should read:**
- Flutter app developers
- Mobile team leads
- Anyone implementing client-side API integration

## Key Features

### Multi-Region Support
All product-related endpoints support region-specific data via the `X-Region-Code` header:

```
X-Region-Code: TM
```

### Authentication
JWT Bearer token authentication with automatic token refresh:

```
Authorization: Bearer {access_token}
```

### Response Format
All responses follow a standard format:

```json
{
  "success": true,
  "data": { /* response data */ },
  "meta": { /* pagination data */ }
}
```

### Pagination
List endpoints support cursor-based pagination:

```
GET /products?skip=0&limit=20
```

### Error Handling
Consistent error responses with machine-readable codes:

```json
{
  "success": false,
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Human readable error message",
    "details": {}
  }
}
```

## API Endpoints Overview

### Authentication
- `POST /auth/register` - Register new user
- `POST /auth/login` - Login with email/password
- `POST /auth/refresh` - Refresh access token
- `POST /auth/change-password` - Change password
- `POST /auth/logout` - Logout

### Products
- `GET /products` - List products with filtering
- `GET /products/{id}` - Get product details
- `GET /products/{id}/images` - Get product images

### Collections
- `GET /collections` - List curated collections
- `GET /collections/{id}` - Get collection details

### Orders
- `POST /orders` - Create new order
- `GET /orders` - Get user's orders
- `GET /orders/{id}` - Get order details
- `POST /orders/{id}/cancel` - Cancel order

### Cart
- `POST /cart/validate` - Validate cart and calculate totals
- `GET /cart/check-availability/{product_id}` - Check stock
- `GET /cart/delivery-fee` - Calculate delivery fee

### Categories & Sections
- `GET /product-sections` - List sections
- `GET /products/categories` - List categories

### User Profile
- `GET /users/me` - Get current user
- `PATCH /users/me` - Update profile
- `GET /users/me/addresses` - Get saved addresses
- `POST /users/me/addresses` - Add address

### Regions
- `GET /regions` - List available regions
- `GET /regions/current` - Get current region

### Search
- `GET /search` - Global search across products, collections, categories

## Quick Start

### For Flutter Developers

1. Read the [Flutter API Guide](./FLUTTER_API_GUIDE.md)
2. Import the [OpenAPI specification](./flutter-api-documentation.yaml) into your API client tool
3. Follow the authentication flow examples
4. Use the provided Dart code examples as templates
5. Implement the repository pattern for data access

### For Backend Developers

1. Review the [OpenAPI specification](./flutter-api-documentation.yaml) for endpoint contracts
2. Ensure endpoints follow the documented request/response format
3. Return consistent error responses with appropriate HTTP status codes
4. Support the `X-Region-Code` header for region-specific operations

### For QA/Testing

1. Import [OpenAPI specification](./flutter-api-documentation.yaml) into Postman or Insomnia
2. Use provided examples for request payloads
3. Validate responses match documented schemas
4. Test error scenarios and edge cases

## Authentication Details

### Token Types

**Access Token (JWT)**
- Expires: 1 hour
- Used for API requests
- Attached via `Authorization: Bearer {token}` header
- Automatically refreshed by client on expiration

**Refresh Token (JWT)**
- Expires: 30 days
- Used to obtain new access tokens
- Must be stored securely
- Invalidated on logout

### Token Refresh Flow

```
1. Client makes API request with expired access token
2. Server returns 401 Unauthorized
3. Client uses refresh token to request new access token
4. Server validates refresh token and returns new pair
5. Client retries original request with new access token
6. Server processes request successfully
```

## Error Codes

| Code | HTTP Status | Description |
|------|------------|-------------|
| VALIDATION_ERROR | 422 | Request validation failed |
| UNAUTHORIZED | 401 | Invalid or missing authentication |
| FORBIDDEN | 403 | Insufficient permissions |
| NOT_FOUND | 404 | Resource not found |
| CONFLICT | 409 | Resource already exists |
| RATE_LIMITED | 429 | Too many requests |
| INTERNAL_ERROR | 500 | Server error |
| EMAIL_ALREADY_EXISTS | 400 | Email already registered |
| INVALID_CREDENTIALS | 401 | Login failed |
| PRODUCT_OUT_OF_STOCK | 400 | Product unavailable |
| ORDER_ERROR | 400 | Order creation failed |

## Order Status Workflow

```
pending
    ↓
payment_confirmed (after payment received)
    ↓
processing (being prepared)
    ↓
ready_for_delivery
    ↓
out_for_delivery
    ↓
delivered
```

Alternative paths:
- `pending` → `cancelled`
- `payment_confirmed` → `refunded` (on cancellation)

## Payment Methods

- **card** - Credit/debit card (real-time processing)
- **cash** - Cash on delivery
- **bank_transfer** - Bank transfer (manual verification)

## Delivery Methods

- **delivery** - Courier delivery
- **pickup** - Store pickup

## Data Types

### Decimal Numbers
All monetary values (prices, fees) are strings formatted as decimals:

```json
{
  "price": "2500.00",
  "delivery_fee": "300.50"
}
```

Use decimal parsing libraries to avoid floating-point precision issues:
- Dart: Use `Decimal` package
- JavaScript: Use `decimal.js` or `big.js`

### Dates and Times
All timestamps are ISO 8601 formatted with timezone:

```json
{
  "created_at": "2024-01-05T10:30:00Z",
  "delivery_date": "2024-01-15T10:00:00Z"
}
```

### Enums
String enums for status, methods, and roles:

```json
{
  "status": "pending",
  "payment_method": "cash",
  "role": "customer"
}
```

## Rate Limiting

API implements rate limiting per user:

- **Authenticated Users**: 1000 requests/hour
- **Unauthenticated Users**: 100 requests/hour

Rate limit headers:

```
X-RateLimit-Limit: 1000
X-RateLimit-Remaining: 999
X-RateLimit-Reset: 1672531200
```

## CORS Support

API supports CORS for browser-based clients. Ensure your frontend domain is added to the allowed origins.

### Allowed Origins
- Development: `http://localhost:3000`
- Production: `https://app.plantmama.com`

## Version Information

**API Version**: 1.0.0

**Current Status**: Stable

**Last Updated**: December 2024

## Support

For API integration support:

- **Email**: support@plantmama.com
- **Documentation Issues**: Create issue in repository
- **Bug Reports**: Report to support team with reproduction steps

## Contributing

API documentation is maintained alongside the codebase. When adding new endpoints:

1. Update OpenAPI specification first
2. Update this README if adding new features
3. Add Dart examples to Flutter guide
4. Document all request/response schemas
5. Include error scenarios

## Related Documentation

- [Backend README](../backend/README.md)
- [Frontend README](../admin/README.md)
- [Project Setup Guide](../SETUP.md)
- [Database Schema](../database/schema.md)

---

Last Updated: December 6, 2024
