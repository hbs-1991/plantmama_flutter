# Phone Number Registration System

## Overview

This implementation provides a secure, optional phone number registration system for Django users. The system follows security best practices with rate limiting, suspicious activity detection, and comprehensive validation.

## Features

- ✅ **Optional Registration**: Users can register with phone number instead of email
- ✅ **SMS Verification**: Secure 6-digit SMS codes with 10-minute expiry
- ✅ **Rate Limiting**: Protected against spam and abuse
- ✅ **Security Measures**: Suspicious activity detection and IP blocking  
- ✅ **Comprehensive Testing**: Full test coverage for all components
- ✅ **Cleanup Commands**: Automated cleanup of expired verifications

## API Endpoints

### 1. Start Phone Registration
**POST** `/api/users/register-phone-start/`

```json
{
    "phone": "+993123456789",
    "first_name": "John",
    "last_name": "Doe", 
    "email": "john@example.com",
    "password": "secure_password123"
}
```

**Response (201 Created):**
```json
{
    "message": "Код подтверждения отправлен",
    "phone": "+993123456789", 
    "status": "verification_sent"
}
```

### 2. Verify Code & Complete Registration
**POST** `/api/users/register-phone-verify/`

```json
{
    "phone": "+993123456789",
    "code": "123456"
}
```

**Response (201 Created):**
```json
{
    "message": "Регистрация завершена успешно",
    "status": "registration_complete",
    "user": {
        "id": 1,
        "username": "+993123456789",
        "phone": "+993123456789",
        "phone_verified": true,
        "first_name": "John",
        "last_name": "Doe"
    }
}
```

### 3. Resend Verification Code
**POST** `/api/users/register-phone-resend/`

```json
{
    "phone": "+993123456789"
}
```

**Response (200 OK):**
```json
{
    "message": "Код подтверждения отправлен",
    "phone": "+993123456789",
    "status": "code_resent"
}
```

### 4. Check Registration Status
**POST** `/api/users/register-phone-status/`

```json
{
    "phone": "+993123456789"
}
```

**Response (200 OK):**
```json
{
    "phone": "+993123456789",
    "status": "pending_verification",
    "expires_at": "2025-01-08T12:45:00Z",
    "attempts_remaining": 2,
    "can_resend": true
}
```

## Security Features

### Rate Limiting
- **Registration**: 3 attempts per hour per IP/phone
- **Verification**: 5 attempts per 10 minutes per phone
- **Resend**: 3 resends per hour per phone

### Security Measures
- **IP Blocking**: Automatic blocking after excessive failed attempts
- **Phone Blocking**: Per-phone rate limiting
- **Suspicious Activity Detection**: Sequential phone number detection
- **Code Security**: 6-digit random codes with 10-minute expiry
- **Attempt Limiting**: Maximum 3 verification attempts per code

### Throttling Classes
```python
# Custom throttle classes in apps/users/throttling.py
PhoneRegistrationThrottle  # 3/hour per IP+phone
PhoneVerificationThrottle  # 5/10min per phone  
PhoneResendThrottle       # 3/hour per phone
```

## Models

### User Model Extensions
```python
class User(AbstractUser):
    phone = models.CharField(max_length=20, unique=True, null=True)
    phone_verified = models.BooleanField(default=False)
```

### PhoneVerification Model
```python
class PhoneVerification(models.Model):
    phone = models.CharField(max_length=20, db_index=True)
    code = models.CharField(max_length=6)
    verification_type = models.CharField(max_length=20)
    user = models.ForeignKey(User, null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    expires_at = models.DateTimeField()
    attempts = models.PositiveSmallIntegerField(default=0)
    is_verified = models.BooleanField(default=False)
    registration_data = models.JSONField(null=True, blank=True)
```

## Services Architecture

### PhoneVerificationService
Core service for phone verification operations:
- `initiate_phone_verification()` - Start verification process
- `verify_code()` - Verify SMS code
- `resend_code()` - Resend verification code
- `complete_phone_registration()` - Create user after verification

### PhoneRegistrationService  
High-level service for phone registration:
- `start_phone_registration()` - Begin registration flow
- `complete_phone_registration()` - Complete registration with verification

## Configuration

### Settings (config/settings/base.py)
```python
# Phone Registration Security Settings
PHONE_REG_MAX_ATTEMPTS_PER_IP = 10
PHONE_REG_MAX_ATTEMPTS_PER_PHONE = 5  
PHONE_REG_BLOCK_TIME_MINUTES = 60
PHONE_REG_CODE_LENGTH = 6
PHONE_REG_CODE_LIFETIME_MINUTES = 10

# DRF Throttling
REST_FRAMEWORK = {
    "DEFAULT_THROTTLE_RATES": {
        "phone_registration": "3/hour",
        "phone_verification": "5/10min", 
        "phone_resend": "3/hour",
    },
}
```

## Testing

### Run Phone Registration Tests
```bash
python manage.py test apps.users.tests_phone_registration
```

### Test Coverage Areas
- ✅ Phone number validation
- ✅ Verification model functionality  
- ✅ Service layer logic
- ✅ API endpoint integration
- ✅ Security features
- ✅ Rate limiting
- ✅ Complete registration flows

## SMS Integration

### Development Mode
In `DEBUG=True` mode, SMS codes are logged to console:
```
🔐 SMS CODE for +993123456789: 123456
```

### Production Setup
To integrate with SMS providers, update `PhoneVerificationService._send_sms_code()`:

```python
# Example integrations:
# - Twilio: twilio.rest.Client()
# - AWS SNS: boto3.client('sns')
# - Vonage: vonage.Client()

def _send_sms_code(cls, phone: str, code: str):
    if settings.DEBUG:
        logger.info(f"SMS CODE for {phone}: {code}")
        return True, "Development mode"
    
    # Production SMS integration
    try:
        # Example: Twilio
        # client.messages.create(
        #     body=f"Your verification code: {code}",
        #     from_='+1234567890',
        #     to=phone
        # )
        return True, "SMS sent"
    except Exception as e:
        return False, str(e)
```

## Maintenance

### Cleanup Expired Verifications
Run cleanup command (recommended in cron):
```bash
python manage.py cleanup_phone_verifications
```

### Cron Job Example
```bash
# Run cleanup every hour
0 * * * * cd /path/to/project && python manage.py cleanup_phone_verifications
```

## Database Migration

After implementing the system, create and run the migration:
```bash
python manage.py makemigrations users --name add_phone_verification
python manage.py migrate
```

## Validation Rules

### Phone Number Format
- **Length**: 8-15 digits after cleaning
- **Characters**: Only digits allowed after preprocessing
- **Uniqueness**: Must be unique across verified users
- **Examples**: `+993123456789`, `123456789`, `+1234567890`

### Code Format  
- **Length**: Exactly 6 digits
- **Type**: Numeric only
- **Generation**: Cryptographically secure random
- **Expiry**: 10 minutes from generation

## Error Handling

### Common Error Responses

**Invalid Phone Number (400)**
```json
{
    "phone": ["Номер телефона должен содержать от 8 до 15 цифр"]
}
```

**User Already Exists (400)**
```json
{
    "error": "Пользователь с таким номером уже зарегистрирован"
}
```

**Rate Limited (429)**
```json
{
    "error": "Превышен лимит попыток. Попробуйте позже.",
    "retry_after": 3600
}
```

**Invalid Code (400)**
```json
{
    "error": "Неверный код. Осталось попыток: 2"
}
```

**Code Expired (400)**
```json
{
    "error": "Превышено количество попыток. Запросите новый код."
}
```

## Integration Examples

### Frontend Integration (JavaScript)
```javascript
// Start registration
const startRegistration = async (userData) => {
    const response = await fetch('/api/users/register-phone-start/', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(userData)
    });
    return response.json();
};

// Verify code
const verifyCode = async (phone, code) => {
    const response = await fetch('/api/users/register-phone-verify/', {
        method: 'POST', 
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ phone, code })
    });
    return response.json();
};
```

### React Hook Example
```jsx
const usePhoneRegistration = () => {
    const [status, setStatus] = useState('idle');
    const [phone, setPhone] = useState('');
    
    const startRegistration = async (userData) => {
        setStatus('sending');
        try {
            const result = await api.startPhoneRegistration(userData);
            if (result.status === 'verification_sent') {
                setStatus('verification_pending');
                setPhone(result.phone);
            }
            return result;
        } catch (error) {
            setStatus('error');
            throw error;
        }
    };
    
    const verifyCode = async (code) => {
        try {
            const result = await api.verifyPhoneCode(phone, code);
            if (result.status === 'registration_complete') {
                setStatus('completed');
            }
            return result;
        } catch (error) {
            setStatus('error');
            throw error;
        }
    };
    
    return { status, startRegistration, verifyCode };
};
```

## Security Considerations

### Best Practices Implemented
- ✅ **Rate Limiting**: Multiple layers of protection
- ✅ **Code Expiry**: Short-lived verification codes  
- ✅ **Attempt Limits**: Maximum verification attempts
- ✅ **IP Tracking**: Block suspicious IP addresses
- ✅ **Phone Validation**: Secure phone number validation
- ✅ **Data Encryption**: Secure code generation
- ✅ **Audit Logging**: Comprehensive logging for monitoring

### Production Checklist
- [ ] Configure SMS provider integration
- [ ] Set up monitoring and alerting
- [ ] Configure cron job for cleanup
- [ ] Review rate limiting settings
- [ ] Test SMS delivery in production
- [ ] Set up log rotation
- [ ] Configure database indexes for performance

## Troubleshooting

### Common Issues

**SMS Codes Not Received**
- Check SMS provider configuration
- Verify phone number format
- Check delivery logs

**Rate Limiting Too Strict**  
- Adjust `PHONE_REG_*` settings
- Check throttle rates in DRF settings

**Database Performance**
- Ensure indexes are created
- Run cleanup command regularly
- Monitor verification table size

**Memory/Cache Issues**
- Configure Redis for production caching
- Monitor cache hit rates
- Check throttling cache usage