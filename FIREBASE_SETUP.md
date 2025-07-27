# Firebase Setup Guide for Weather App

This guide will help you set up Firebase Authentication with Google Sign-In and Firestore for your Flutter weather app.

## Prerequisites

1. A Google account
2. Flutter SDK installed
3. Firebase CLI installed (optional but recommended)

## Step 1: Create a Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click "Create a project" or "Add project"
3. Enter a project name (e.g., "weather-app-12345")
4. Choose whether to enable Google Analytics (recommended)
5. Click "Create project"

## Step 2: Enable Authentication

1. In your Firebase project, go to "Authentication" in the left sidebar
2. Click "Get started"
3. Go to the "Sign-in method" tab
4. Click on "Google" provider
5. Enable it and configure:
   - Project support email: your email
   - Web SDK configuration: Add your domain (for web)
6. Click "Save"

## Step 3: Enable Firestore Database

1. In your Firebase project, go to "Firestore Database" in the left sidebar
2. Click "Create database"
3. Choose "Start in test mode" (for development)
4. Select a location for your database
5. Click "Done"

## Step 4: Configure Security Rules

In Firestore Database > Rules, update the rules to:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users can only access their own data
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
      
      // Allow access to subcollections
      match /{document=**} {
        allow read, write: if request.auth != null && request.auth.uid == userId;
      }
    }
  }
}
```

## Step 5: Add Your App to Firebase

### For Android:

1. In Firebase Console, click the Android icon
2. Enter your Android package name: `com.example.weather_app`
3. Enter app nickname: "Weather App"
4. Click "Register app"
5. Download the `google-services.json` file
6. Place it in `android/app/` directory

### For iOS:

1. In Firebase Console, click the iOS icon
2. Enter your iOS bundle ID: `com.example.weatherApp`
3. Enter app nickname: "Weather App"
4. Click "Register app"
5. Download the `GoogleService-Info.plist` file
6. Place it in `ios/Runner/` directory

### For Web:

1. In Firebase Console, click the Web icon
2. Enter app nickname: "Weather App Web"
3. Click "Register app"
4. Copy the Firebase config object

## Step 6: Update Firebase Configuration

Replace the placeholder values in `lib/firebase_options.dart` with your actual Firebase configuration:

```dart
static const FirebaseOptions web = FirebaseOptions(
  apiKey: 'your-actual-web-api-key',
  appId: 'your-actual-web-app-id',
  messagingSenderId: 'your-actual-sender-id',
  projectId: 'your-actual-project-id',
  authDomain: 'your-actual-project-id.firebaseapp.com',
  storageBucket: 'your-actual-project-id.appspot.com',
);

static const FirebaseOptions android = FirebaseOptions(
  apiKey: 'your-actual-android-api-key',
  appId: 'your-actual-android-app-id',
  messagingSenderId: 'your-actual-sender-id',
  projectId: 'your-actual-project-id',
  storageBucket: 'your-actual-project-id.appspot.com',
);

// Update iOS and other platforms similarly
```

## Step 7: Configure Google Sign-In

### For Android:

1. In Firebase Console, go to Project Settings
2. Add your SHA-1 fingerprint:
   ```bash
   # For debug builds
   keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android
   
   # For release builds
   keytool -list -v -keystore your-release-key.keystore -alias your-key-alias
   ```

### For iOS:

1. In Firebase Console, go to Project Settings
2. Add your iOS bundle ID
3. Download the updated `GoogleService-Info.plist`

## Step 8: Install Dependencies

Run the following command to install all required dependencies:

```bash
flutter pub get
```

## Step 9: Test the Setup

1. Run your app: `flutter run`
2. Try signing in with Google
3. Check if user data is saved to Firestore
4. Test the favorites and history features

## Troubleshooting

### Common Issues:

1. **Google Sign-In not working**: Make sure you've added the correct SHA-1 fingerprint for Android
2. **Firestore permission denied**: Check your security rules
3. **Build errors**: Make sure all dependencies are properly installed

### Debug Commands:

```bash
# Check if Firebase is properly configured
flutter doctor

# Clean and rebuild
flutter clean
flutter pub get
flutter run
```

## Security Considerations

1. **Never commit API keys to version control**
2. **Use environment variables for sensitive data**
3. **Set up proper Firestore security rules**
4. **Enable App Check for production**

## Production Deployment

Before deploying to production:

1. Update Firestore security rules to be more restrictive
2. Enable App Check
3. Set up proper authentication methods
4. Configure proper CORS settings for web
5. Set up monitoring and analytics

## Support

If you encounter issues:

1. Check the [Firebase documentation](https://firebase.google.com/docs)
2. Check the [Flutter Firebase documentation](https://firebase.flutter.dev/)
3. Review the [Google Sign-In documentation](https://developers.google.com/identity/sign-in/android)

## Features Added

With this setup, your weather app now includes:

- ✅ Google Sign-In authentication
- ✅ User profile management
- ✅ Weather search history
- ✅ Favorite cities management
- ✅ Real-time data synchronization
- ✅ Secure data access
- ✅ Cross-platform support

The app will automatically save weather searches to the user's history and allow them to manage their favorite cities, all synchronized with Firebase. 