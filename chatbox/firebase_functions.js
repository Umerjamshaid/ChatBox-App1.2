// Firebase Cloud Functions for ChatBox
// Deploy this to Firebase Functions for secure token generation

const functions = require('firebase-functions');
const jwt = require('jsonwebtoken');

// GetStream configuration
const STREAM_API_KEY = functions.config().getstream?.api_key || 'h3bkh4ayyxaz';
const STREAM_API_SECRET = functions.config().getstream?.api_secret || 'your-api-vvpx83p7p86q7mgt7psaqw7hfjq86hqejzugxsezxqfxyfgz2sffvvgmv6q79qbq';

// Generate JWT token for GetStream
exports.generateStreamToken = functions.https.onCall(async (data, context) => {
  // Verify Firebase Authentication
  if (!context.auth) {
    throw new functions.https.HttpsError(
      'unauthenticated',
      'User must be authenticated to generate tokens.'
    );
  }

  const userId = data.userId || context.auth.uid;

  try {
    // Create JWT payload for GetStream
    const payload = {
      user_id: userId,
      exp: Math.floor(Date.now() / 1000) + (24 * 60 * 60), // 24 hours
      iat: Math.floor(Date.now() / 1000),
    };

    // Sign the token with GetStream secret
    const token = jwt.sign(payload, STREAM_API_SECRET, {
      algorithm: 'HS256',
      header: {
        alg: 'HS256',
        typ: 'JWT',
      },
    });

    return {
      token: token,
      userId: userId,
      expiresAt: payload.exp,
    };
  } catch (error) {
    console.error('Token generation error:', error);
    throw new functions.https.HttpsError(
      'internal',
      'Failed to generate authentication token.'
    );
  }
});

// Alternative: Simple token generation for development
exports.generateDevToken = functions.https.onCall(async (data, context) => {
  // This is for development only - NOT for production
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated.');
  }

  const userId = data.userId || context.auth.uid;
  const timestamp = Date.now();
  const message = `${STREAM_API_KEY}${userId}${timestamp}`;

  // Simple hash for development (not secure for production)
  const crypto = require('crypto');
  const hash = crypto.createHash('sha256').update(message).digest('hex');
  const token = `${userId}_${hash.substring(0, 32)}`;

  return {
    token: token,
    userId: userId,
    note: 'This is a development token. Use generateStreamToken for production.',
  };
});