# PlantMama Django API Documentation

## Overview

This document provides comprehensive documentation for all API endpoints in the PlantMama Django application. The API follows REST principles and supports both authenticated and anonymous users.


### Authentication
The API uses JWT (JSON Web Token) authentication. Include the token in the Authorization header:
```
Authorization: Bearer <your_jwt_token>
```

### Response Format
All responses follow a consistent JSON format:
```json
{
  "success": true,
  "data": {},
  "message": "Success message",
  "errors": []
}
```

### Error Codes
- `400` - Bad Request: Invalid request parameters
- `401` - Unauthorized: Authentication required
- `403` - Forbidden: Insufficient permissions
- `404` - Not Found: Resource not found
- `500` - Internal Server Error: Server error

---

## Authentication Endpoints

### JWT Token Management

#### Get JWT Token (Login)
```http
POST /api/token/
```

**Request Body:**
```json
{
  "email": "user@example.com",
  "password": "password123"
}
```

**Response:**
```json
{
  "access": "jwt_access_token",
  "refresh": "jwt_refresh_token"
}
```

#### Refresh JWT Token
```http
POST /api/token/refresh/
```

**Request Body:**
```json
{
  "refresh": "jwt_refresh_token"
}
```

**Response:**
```json
{
  "access": "new_jwt_access_token"
}
```

#### Verify JWT Token
```http
POST /api/token/verify/
```

**Request Body:**
```json
{
  "token": "jwt_token_to_verify"
}
```

**Response:**
```json
{}
```

---

## Users API

### User Management

#### Register New User
```http
POST /api/users/register/
```

**Request Body:**
```json
{
  "email": "user@example.com",
  "password": "password123",
  "first_name": "John",
  "last_name": "Doe",
  "phone": "+1234567890"
}
```

**Response:**
```json
{
  "id": 1,
  "username": "user@example.com",
  "email": "user@example.com",
  "first_name": "John",
  "last_name": "Doe",
  "phone": "+1234567890",
  "date_joined": "2024-01-01T10:00:00Z",
  "addresses": [],
  "default_address": null
}
```

#### Get Current User Profile
```http
GET /api/users/me/
```
*Requires Authentication*

**Response:**
```json
{
  "id": 1,
  "username": "user@example.com",
  "email": "user@example.com",
  "first_name": "John",
  "last_name": "Doe",
  "phone": "+1234567890",
  "date_joined": "2024-01-01T10:00:00Z",
  "addresses": [
    {
      "id": 1,
      "label": "home",
      "street_address": "123 Main St",
      "apartment": "Apt 4B",
      "city": "New York",
      "postal_code": "10001",
      "country": "USA",
      "is_default": true,
      "is_active": true,
      "created_at": "2024-01-01T10:00:00Z",
      "updated_at": "2024-01-01T10:00:00Z"
    }
  ],
  "default_address": {
    "id": 1,
    "label": "home",
    "street_address": "123 Main St",
    "apartment": "Apt 4B",
    "city": "New York",
    "postal_code": "10001",
    "country": "USA",
    "is_default": true,
    "is_active": true,
    "created_at": "2024-01-01T10:00:00Z",
    "updated_at": "2024-01-01T10:00:00Z"
  }
}
```

#### Update User Profile
```http
PUT /api/users/update_profile/
```
*Requires Authentication*

**Request Body:**
```json
{
  "first_name": "John",
  "last_name": "Smith",
  "phone": "+1234567890"
}
```

#### Change Password
```http
POST /api/users/change_password/
```
*Requires Authentication*

**Request Body:**
```json
{
  "old_password": "old_password",
  "new_password": "new_password",
  "confirm_password": "new_password"
}
```

### Address Management

#### Get User Addresses
```http
GET /api/users/addresses/
```
*Requires Authentication*

**Response:**
```json
[
  {
    "id": 1,
    "label": "home",
    "street_address": "123 Main St",
    "apartment": "Apt 4B",
    "city": "New York",
    "postal_code": "10001",
    "country": "USA",
    "is_default": true,
    "is_active": true,
    "created_at": "2024-01-01T10:00:00Z",
    "updated_at": "2024-01-01T10:00:00Z"
  }
]
```

#### Add New Address
```http
POST /api/users/add_address/
```
*Requires Authentication*

**Request Body:**
```json
{
  "label": "work",
  "street_address": "456 Office Ave",
  "apartment": "Suite 200",
  "city": "New York",
  "postal_code": "10002",
  "country": "USA",
  "is_default": false
}
```

#### Update Address
```http
PUT /api/users/update_address/
```
*Requires Authentication*

**Request Body:**
```json
{
  "address_id": 1,
  "street_address": "789 New St",
  "is_default": true
}
```

#### Delete Address
```http
DELETE /api/users/delete_address/
```
*Requires Authentication*

**Request Body:**
```json
{
  "address_id": 1
}
```

### Favorites Management

#### Get User Favorites
```http
GET /api/users/favorites/
```
*Requires Authentication*

**Response:**
```json
{
  "count": 1,
  "next": null,
  "previous": null,
  "results": [
    {
      "id": 1,
      "product": {
        "id": 1,
        "name": "Red Rose",
        "price": "15.99",
        "discount_price": "12.99",
        "images": [
          {
            "id": 1,
            "image": "/media/products/rose.jpg",
            "alt_text": "Red Rose"
          }
        ],
        "category": {
          "id": 1,
          "name": "Flowers"
        }
      },
      "created_at": "2024-01-01T10:00:00Z"
    }
  ]
}
```

#### Add to Favorites
```http
POST /api/users/add_to_favorites/
```
*Requires Authentication*

**Request Body:**
```json
{
  "product_id": 1
}
```

#### Remove from Favorites
```http
POST /api/users/remove_from_favorites/
```
*Requires Authentication*

**Request Body:**
```json
{
  "product_id": 1
}
```

#### Check if Product is Favorite
```http
GET /api/users/is_favorite/?product_id=1
```
*Requires Authentication*

**Response:**
```json
{
  "is_favorite": true
}
```

### Admin Functions

#### Get Users List (Admin Only)
```http
GET /api/users/
```
*Requires Admin Authentication*

#### Get User Statistics (Admin Only)
```http
GET /api/users/stats/
```
*Requires Admin Authentication*

**Response:**
```json
{
  "total_users": 100,
  "active_users": 95,
  "new_users_today": 5,
  "new_users_week": 20,
  "new_users_month": 50,
  "staff_count": 3
}
```

#### Search Users (Admin Only)
```http
GET /api/users/search/?q=john&ordering=-date_joined
```
*Requires Admin Authentication*

#### Toggle User Active Status (Admin Only)
```http
POST /api/users/{id}/toggle_active/
```
*Requires Admin Authentication*

**Request Body:**
```json
{
  "is_active": false
}
```

---

## Products API

### Product Catalog

#### Get Products List
```http
GET /api/products/
```

**Query Parameters:**
- `category` - Filter by category ID
- `section` - Filter by section ID
- `is_featured` - Filter featured products (true/false)
- `occasions` - Filter by occasion ID
- `search` - Search in name/description
- `ordering` - Sort by price, created_at, name
- `page` - Page number for pagination
- `page_size` - Items per page

**Response:**
```json
{
  "count": 100,
  "next": "https://ae0a6c0c1f30.ngrok-free.appapi/products/?page=2",
  "previous": null,
  "results": [
    {
      "id": 1,
      "name": "Red Rose",
      "slug": "red-rose",
      "description": "Beautiful red rose",
      "short_description": "Perfect for romantic occasions",
      "price": "15.99",
      "discount_price": "12.99",
      "stock": 50,
      "sku": "ROSE001",
      "is_active": true,
      "is_featured": true,
      "created_at": "2024-01-01T10:00:00Z",
      "updated_at": "2024-01-01T10:00:00Z",
      "category": {
        "id": 1,
        "name": "Flowers",
        "slug": "flowers",
        "section": {
          "id": 1,
          "name": "Plants",
          "slug": "plants"
        }
      },
      "images": [
        {
          "id": 1,
          "image": "/media/products/rose.jpg",
          "alt_text": "Red Rose",
          "is_primary": true
        }
      ],
      "occasions": [
        {
          "id": 1,
          "name": "Valentine's Day",
          "slug": "valentines-day"
        }
      ],
      "average_rating": 4.5,
      "review_count": 10,
      "composition": "Fresh red roses",
      "care_instructions": "Keep in cool water"
    }
  ]
}
```

#### Get Single Product
```http
GET /api/products/{id}/
```

**Response:** Same as single product object from list endpoint.

#### Get Featured Products
```http
GET /api/products/featured/
```

#### Search Products
```http
GET /api/products/search/?q=rose&category=1&occasion=1
```

**Query Parameters:**
- `q` - Search query
- `category` - Filter by category ID
- `occasion` - Filter by occasion ID

#### Advanced Search with Autocomplete
```http
GET /api/products/advanced_search/?q=ros&suggest=true
```

**Query Parameters:**
- `q` - Search query
- `suggest` - Return suggestions only (true/false)

**Response (suggestions):**
```json
{
  "suggestions": ["rose", "roses", "red rose"],
  "products": []
}
```

#### Get Product Analytics (Admin Only)
```http
GET /api/products/analytics/?timeframe=30d&section=1
```
*Requires Admin Authentication*

**Query Parameters:**
- `timeframe` - 7d, 30d, 90d, 365d
- `section` - Section ID filter

#### Get Quick Stats (Admin Only)
```http
GET /api/products/quick_stats/
```
*Requires Admin Authentication*

**Response:**
```json
{
  "total_products": 100,
  "active_products": 95,
  "products_in_stock": 80,
  "featured_products": 20,
  "average_price": 25.50,
  "average_rating": 4.2
}
```

### Product Management (Admin Only)

#### Create Product
```http
POST /api/products/
```
*Requires Admin Authentication*

**Request Body:**
```json
{
  "name": "Yellow Tulip",
  "description": "Fresh yellow tulip",
  "price": "8.99",
  "stock": 25,
  "sku": "TUL001",
  "category": 1,
  "is_active": true,
  "is_featured": false
}
```

#### Update Product
```http
PUT /api/products/{id}/
```
*Requires Admin Authentication*

#### Delete Product
```http
DELETE /api/products/{id}/
```
*Requires Admin Authentication*

#### Duplicate Product
```http
POST /api/products/{id}/duplicate/
```
*Requires Admin Authentication*

#### Toggle Product Status
```http
POST /api/products/{id}/toggle_status/
```
*Requires Admin Authentication*

#### Bulk Operations
```http
POST /api/products/bulk_create/
```
```http
PATCH /api/products/bulk_update/
```
```http
DELETE /api/products/bulk_delete/
```
*Require Admin Authentication*

#### Import Products
```http
POST /api/products/import_data/
```
*Requires Admin Authentication*

**Request Body (multipart/form-data):**
- `file` - CSV/Excel/JSON file
- `format` - csv, xlsx, json
- `enhanced` - Use enhanced import service (true/false)

#### Validate Import File
```http
POST /api/products/validate_import/
```
*Requires Admin Authentication*

#### Export Products
```http
GET /api/products/export_data/?format=csv
```
*Requires Admin Authentication*

### Product Reviews

#### Get Product Reviews
```http
GET /api/products/{id}/reviews/
```

**Response:**
```json
{
  "count": 5,
  "next": null,
  "previous": null,
  "results": [
    {
      "id": 1,
      "user": {
        "id": 1,
        "first_name": "John",
        "last_name": "Doe"
      },
      "product": 1,
      "title": "Great product!",
      "comment": "Beautiful roses, fresh and long-lasting",
      "rating": 5,
      "is_verified_purchase": true,
      "created_at": "2024-01-01T10:00:00Z"
    }
  ]
}
```

#### Add Product Review
```http
POST /api/products/{id}/add_review/
```
*Requires Authentication*

**Request Body:**
```json
{
  "title": "Great product!",
  "comment": "Beautiful roses, fresh and long-lasting",
  "rating": 5
}
```

#### Get All Reviews
```http
GET /api/products/reviews/
```

**Query Parameters:**
- `product` - Filter by product ID
- `rating` - Filter by rating
- `is_verified_purchase` - Filter verified purchases
- `search` - Search in title/comment

#### Create Review
```http
POST /api/products/reviews/
```
*Requires Authentication*

### Categories Management

#### Get Categories
```http
GET /api/products/categories/
```

**Response:**
```json
[
  {
    "id": 1,
    "name": "Flowers",
    "slug": "flowers",
    "description": "Beautiful flowers for all occasions",
    "section": {
      "id": 1,
      "name": "Plants",
      "slug": "plants"
    },
    "parent": null,
    "children": [
      {
        "id": 2,
        "name": "Roses",
        "slug": "roses"
      }
    ],
    "product_count": 25,
    "is_active": true,
    "order": 1
  }
]
```

#### Get Category Products
```http
GET /api/products/categories/{id}/products/
```

#### Category Admin Operations
```http
POST /api/products/categories/bulk_create/
```
```http
PATCH /api/products/categories/bulk_update/
```
```http
DELETE /api/products/categories/bulk_delete/
```
*Require Admin Authentication*

### Sections Management

#### Get Sections
```http
GET /api/products/sections/
```

**Response:**
```json
[
  {
    "id": 1,
    "name": "Plants",
    "slug": "plants",
    "description": "All types of plants",
    "icon": "plant-icon.svg",
    "is_active": true,
    "order": 1
  }
]
```

#### Get Section Categories
```http
GET /api/products/sections/{id}/categories/
```

#### Get Section Products
```http
GET /api/products/sections/{id}/products/
```

#### Get Featured Products in Section
```http
GET /api/products/sections/{id}/featured_products/
```

### Occasions Management

#### Get Occasions
```http
GET /api/products/occasions/
```

**Response:**
```json
[
  {
    "id": 1,
    "name": "Valentine's Day",
    "slug": "valentines-day",
    "description": "Perfect for Valentine's Day",
    "date": "2024-02-14",
    "is_active": true
  }
]
```

#### Get Occasion Products
```http
GET /api/products/occasions/{id}/products/
```

### Promo Codes (Admin Only)

#### Get Promo Codes
```http
GET /api/products/promocodes/
```
*Requires Admin Authentication*

#### Create/Update/Delete Promo Code
```http
POST /api/products/promocodes/
```
```http
PUT /api/products/promocodes/{id}/
```
```http
DELETE /api/products/promocodes/{id}/
```
*Require Admin Authentication*

---

## Cart API

### Cart Management

#### Get User Cart
```http
GET /api/cart/my_cart/
```

**Response:**
```json
{
  "id": 1,
  "user": 1,
  "session_id": null,
  "created_at": "2024-01-01T10:00:00Z",
  "updated_at": "2024-01-01T10:00:00Z",
  "items": [
    {
      "id": 1,
      "product": {
        "id": 1,
        "name": "Red Rose",
        "price": "15.99",
        "discount_price": "12.99",
        "images": [
          {
            "id": 1,
            "image": "/media/products/rose.jpg"
          }
        ]
      },
      "quantity": 2,
      "unit_price": "12.99",
      "total_price": "25.98",
      "created_at": "2024-01-01T10:00:00Z"
    }
  ],
  "total_items": 2,
  "subtotal": "25.98"
}
```

#### Add Item to Cart
```http
POST /api/cart/add_item/
```

**Request Body:**
```json
{
  "product_id": 1,
  "quantity": 2
}
```

#### Update Cart Item
```http
POST /api/cart/update_item/
```

**Request Body:**
```json
{
  "product_id": 1,
  "quantity": 3
}
```

#### Remove Item from Cart
```http
POST /api/cart/remove_item/
```

**Request Body:**
```json
{
  "product_id": 1
}
```

#### Clear Cart
```http
POST /api/cart/clear/
```

### Cart Items Management

#### Get Cart Items
```http
GET /api/cart/items/
```

#### Create/Update/Delete Cart Item
```http
POST /api/cart/items/
```
```http
PUT /api/cart/items/{id}/
```
```http
DELETE /api/cart/items/{id}/
```

---

## Orders API

### Order Management

#### Get User Orders
```http
GET /api/orders/
```
*Requires Authentication*

**Response:**
```json
{
  "count": 5,
  "next": null,
  "previous": null,
  "results": [
    {
      "id": 1,
      "order_number": "202401123456",
      "user": 1,
      "status": {
        "id": 1,
        "name": "Новый",
        "description": "Заказ создан и ожидает обработки"
      },
      "recipient_name": "John Doe",
      "recipient_phone": "+1234567890",
      "recipient_address": "123 Main St, New York, NY 10001",
      "delivery_method": {
        "id": 1,
        "name": "Standard Delivery",
        "price": "5.99",
        "estimated_days": 3
      },
      "delivery_date": "2024-01-15",
      "delivery_time_slot": "10:00-12:00",
      "is_express_delivery": false,
      "payment_method": {
        "id": 1,
        "name": "Credit Card",
        "is_online": true
      },
      "is_paid": false,
      "subtotal": "25.98",
      "delivery_cost": "5.99",
      "total": "31.97",
      "comment": "Please ring the doorbell",
      "created_at": "2024-01-01T10:00:00Z",
      "updated_at": "2024-01-01T10:00:00Z",
      "items": [
        {
          "id": 1,
          "product": {
            "id": 1,
            "name": "Red Rose"
          },
          "product_name": "Red Rose",
          "product_price": "12.99",
          "quantity": 2,
          "total_price": "25.98"
        }
      ]
    }
  ]
}
```

#### Create Order (Checkout)
```http
POST /api/orders/checkout/
```

**Request Body:**
```json
{
  "recipient_name": "John Doe",
  "recipient_phone": "+1234567890",
  "recipient_address": "123 Main St, New York, NY 10001",
  "delivery_method": 1,
  "delivery_date": "2024-01-15",
  "delivery_time_slot": "10:00-12:00",
  "is_express_delivery": false,
  "payment_method": 1,
  "comment": "Please ring the doorbell"
}
```

**Response:** Same as single order object.

#### Get Order Status
```http
GET /api/orders/{id}/status/
```

**Response:**
```json
{
  "status": "Новый",
  "is_paid": false,
  "updated_at": "2024-01-01T10:00:00Z"
}
```

### Delivery Methods

#### Get Delivery Methods
```http
GET /api/orders/delivery-methods/
```

**Response:**
```json
[
  {
    "id": 1,
    "name": "Standard Delivery",
    "description": "Delivery within 3-5 business days",
    "price": "5.99",
    "estimated_days": 3,
    "is_active": true
  },
  {
    "id": 2,
    "name": "Express Delivery",
    "description": "Delivery within 1-2 business days",
    "price": "15.99",
    "estimated_days": 1,
    "is_active": true
  }
]
```

### Payment Methods

#### Get Payment Methods
```http
GET /api/orders/payment-methods/
```

**Response:**
```json
[
  {
    "id": 1,
    "name": "Credit Card",
    "description": "Pay with credit or debit card",
    "is_online": true,
    "is_active": true
  },
  {
    "id": 2,
    "name": "Cash on Delivery",
    "description": "Pay when you receive your order",
    "is_online": false,
    "is_active": true
  }
]
```

### Order Statuses

#### Get Order Statuses
```http
GET /api/orders/order-statuses/
```

**Response:**
```json
[
  {
    "id": 1,
    "name": "Новый",
    "description": "Заказ создан и ожидает обработки",
    "color": "#ffd700",
    "is_final": false
  },
  {
    "id": 2,
    "name": "В обработке",
    "description": "Заказ обрабатывается",
    "color": "#ff8c00",
    "is_final": false
  },
  {
    "id": 3,
    "name": "Доставлен",
    "description": "Заказ успешно доставлен",
    "color": "#32cd32",
    "is_final": true
  }
]
```

---

## Error Responses

### Validation Errors
```json
{
  "field_name": [
    "This field is required."
  ],
  "email": [
    "Enter a valid email address."
  ]
}
```

### Authentication Errors
```json
{
  "detail": "Authentication credentials were not provided."
}
```

### Permission Errors
```json
{
  "detail": "You do not have permission to perform this action."
}
```

### Not Found Errors
```json
{
  "detail": "Not found."
}
```

### Server Errors
```json
{
  "error": "Internal server error message"
}
```

---

## Data Models

### User Model
```json
{
  "id": "integer",
  "username": "string",
  "email": "string (email format)",
  "first_name": "string",
  "last_name": "string",
  "phone": "string",
  "is_active": "boolean",
  "is_staff": "boolean",
  "date_joined": "datetime",
  "last_login": "datetime"
}
```

### Address Model
```json
{
  "id": "integer",
  "label": "string (home, work, other)",
  "street_address": "string",
  "apartment": "string",
  "city": "string",
  "postal_code": "string",
  "country": "string",
  "is_default": "boolean",
  "is_active": "boolean",
  "created_at": "datetime",
  "updated_at": "datetime"
}
```

### Product Model
```json
{
  "id": "integer",
  "name": "string",
  "slug": "string",
  "description": "text",
  "short_description": "string",
  "price": "decimal",
  "discount_price": "decimal (nullable)",
  "stock": "integer",
  "sku": "string (unique)",
  "is_active": "boolean",
  "is_featured": "boolean",
  "composition": "text",
  "care_instructions": "text",
  "created_at": "datetime",
  "updated_at": "datetime"
}
```

### Category Model
```json
{
  "id": "integer",
  "name": "string",
  "slug": "string",
  "description": "text",
  "parent": "integer (nullable, self-reference)",
  "section": "integer (foreign key)",
  "order": "integer",
  "is_active": "boolean",
  "created_at": "datetime",
  "updated_at": "datetime"
}
```

### Order Model
```json
{
  "id": "integer",
  "order_number": "string (unique)",
  "user": "integer (nullable, foreign key)",
  "status": "integer (foreign key)",
  "recipient_name": "string",
  "recipient_phone": "string",
  "recipient_address": "text",
  "delivery_method": "integer (foreign key)",
  "delivery_date": "date",
  "delivery_time_slot": "string",
  "is_express_delivery": "boolean",
  "payment_method": "integer (foreign key)",
  "is_paid": "boolean",
  "subtotal": "decimal",
  "delivery_cost": "decimal",
  "total": "decimal",
  "comment": "text",
  "created_at": "datetime",
  "updated_at": "datetime"
}
```

---

## Rate Limits

- Authentication endpoints: 5 requests per minute
- General API endpoints: 100 requests per minute
- Admin endpoints: 1000 requests per minute

---

## Pagination

Most list endpoints support pagination with the following parameters:
- `page` - Page number (default: 1)
- `page_size` - Items per page (default: 20, max: 100)

Paginated responses include:
```json
{
  "count": 100,
  "next": "https://ae0a6c0c1f30.ngrok-free.appapi/products/?page=2",
  "previous": null,
  "results": []
}
```

---

## Filtering and Searching

### Common Query Parameters:
- `search` - Full-text search
- `ordering` - Sort results (prefix with `-` for descending)
- `is_active` - Filter by active status
- `created_at__gte` - Filter by creation date (greater than or equal)
- `created_at__lte` - Filter by creation date (less than or equal)

### Product-specific filters:
- `category` - Filter by category ID
- `section` - Filter by section ID
- `is_featured` - Filter featured products
- `occasions` - Filter by occasion ID
- `price__gte` - Minimum price
- `price__lte` - Maximum price
- `in_stock` - Only products with stock > 0

### Example:
```http
GET /api/products/?category=1&is_featured=true&price__gte=10&ordering=-created_at
```

---

## Webhooks (Future Enhancement)

The API is designed to support webhooks for:
- Order status changes
- Payment confirmations
- Stock level alerts
- New user registrations

---

## SDK and Client Libraries (Future Enhancement)

Official SDKs will be available for:
- JavaScript/Node.js
- Python
- PHP
- Mobile (React Native, Flutter)

---

## Changelog

### Version 1.0.0 (Current)
- Initial API release
- User management and authentication
- Product catalog with categories and sections
- Shopping cart functionality
- Order management system
- Admin panel integration

### Planned Features
- Real-time notifications
- Advanced analytics
- Inventory management
- Multi-language support
- Payment gateway integrations
- Subscription management

---

## Support

For API support and questions:
- Documentation: This file
- Issues: Check server logs
- Contact: Development team

---

*Last updated: January 2024*r