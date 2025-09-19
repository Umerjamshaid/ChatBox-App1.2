# ChatBox - GetStream Token Setup Guide

## 🚀 Production-Ready Token Generation

This guide explains how to set up secure server-side JWT token generation for GetStream integration.

## 📋 Prerequisites

1. **Firebase CLI** installed: `npm install -g firebase-tools`
2. **Node.js** installed (version 14 or higher)
3. **Firebase project** with Functions enabled
4. **GetStream account** with API key and secret

## 🔧 Setup Instructions

### 1. Initialize Firebase Functions

```bash
# Initialize Firebase in your project
firebase init functions

# Select your Firebase project
# Choose JavaScript for the language
```

### 2. Install Dependencies

```bash
cd functions
npm install jsonwebtoken
```

### 3. Configure Environment Variables

```bash
# Set GetStream configuration
firebase functions:config:set getstream.api_key="your-getstream-api-key"
firebase functions:config:set getstream.api_secret="your-getstream-api-secret"
```

### 4. Deploy Functions

```bash
# Deploy the functions
firebase deploy --only functions
```

### 5. Update Flutter Code

After deployment, update the Cloud Function URL in `lib/services/token_service.dart`:

```dart
// Replace with your actual function URL
static const String _tokenEndpoint = 'https://us-central1-YOUR-PROJECT-ID.cloudfunctions.net/generateStreamToken';
```

## 🔐 Security Features

### ✅ Production Token Generation
- **Server-side JWT creation** using proper cryptographic signing
- **Firebase Authentication** verification before token generation
- **Secure API secret** never exposed to client applications
- **Token expiration** and proper payload structure

### ✅ Development Fallback
- **Graceful degradation** if server is unavailable
- **Development tokens** for local testing
- **Clear error messages** for debugging

## 🏗️ Architecture

```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   Flutter App   │────│ Firebase Functions │────│   GetStream     │
│                 │    │                  │    │                 │
│ • Auth Service  │    │ • JWT Generation │    │ • Chat Service  │
│ • Token Service │    │ • User Verification│    │ • Real-time     │
│ • Stream Client │    │ • Secure Signing  │    │ • Messaging     │
└─────────────────┘    └──────────────────┘    └─────────────────┘
```

## 📝 API Endpoints

### Generate Production Token
```javascript
POST https://us-central1-YOUR-PROJECT.cloudfunctions.net/generateStreamToken
Authorization: Bearer <firebase-id-token>
Content-Type: application/json

{
  "userId": "user123"
}
```

**Response:**
```json
{
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "userId": "user123",
  "expiresAt": 1640995200
}
```

### Generate Development Token (Fallback)
```javascript
POST https://us-central1-YOUR-PROJECT.cloudfunctions.net/generateDevToken
Authorization: Bearer <firebase-id-token>
Content-Type: application/json

{
  "userId": "user123"
}
```

## 🔍 Troubleshooting

### Common Issues

1. **"Function not found" error**
   - Ensure functions are deployed: `firebase deploy --only functions`
   - Check function URL in token service

2. **"Unauthenticated" error**
   - Verify Firebase Authentication is working
   - Check that user is signed in before calling functions

3. **"Internal" error**
   - Check Firebase Functions logs: `firebase functions:log`
   - Verify GetStream API credentials

### Debug Commands

```bash
# View function logs
firebase functions:log

# Test function locally
firebase functions:shell
generateStreamToken({userId: 'test123'})

# Check function status
firebase functions:list
```

## 🚀 Deployment Checklist

- [ ] Firebase project created
- [ ] Functions initialized
- [ ] Dependencies installed (`jsonwebtoken`)
- [ ] Environment variables configured
- [ ] Functions deployed successfully
- [ ] Flutter app updated with correct function URL
- [ ] Authentication working
- [ ] Token generation tested

## 📚 Additional Resources

- [Firebase Functions Documentation](https://firebase.google.com/docs/functions)
- [GetStream Token Documentation](https://getstream.io/chat/docs/tokens_and_authentication/)
- [JWT.io](https://jwt.io/) - JWT debugger and library

## 🔒 Security Notes

- **Never expose API secrets** in client-side code
- **Always use HTTPS** for function calls
- **Implement proper error handling** for production
- **Monitor function usage** and costs
- **Rotate API keys regularly** for security

---

## 🎯 Quick Start (Development)

For immediate development/testing without server setup:

1. The app will automatically fall back to development tokens
2. GetStream connection will work but with limited security
3. Deploy Firebase Functions when ready for production
4. Update the token service with production endpoints

The implementation provides a smooth transition from development to production! 🚀