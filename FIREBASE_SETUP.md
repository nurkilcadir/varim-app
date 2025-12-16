# Firebase Setup Guide

## Quick Fix: Get Your Firebase Web API Keys

Since you're running the app on Chrome (web), you need to configure the **web** Firebase settings.

### Step 1: Go to Firebase Console
1. Open [Firebase Console](https://console.firebase.google.com)
2. Select your project (or create a new one)

### Step 2: Get Web App Configuration
1. Click the **gear icon** (⚙️) next to "Project Overview"
2. Select **"Project settings"**
3. Scroll down to **"Your apps"** section
4. If you don't have a Web app yet:
   - Click **"</>" (Web icon)** to add a web app
   - Register your app with a nickname (e.g., "VARIM Web")
   - Click **"Register app"**
5. You'll see a config object that looks like this:

```javascript
const firebaseConfig = {
  apiKey: "AIzaSyXXXXXXXXXXXXXXXXXXXXXXXXXXXXX",
  authDomain: "your-project-id.firebaseapp.com",
  projectId: "your-project-id",
  storageBucket: "your-project-id.appspot.com",
  messagingSenderId: "123456789012",
  appId: "1:123456789012:web:abcdef1234567890"
};
```

### Step 3: Update firebase_options.dart
Open `lib/firebase_options.dart` and replace the `web` section with your actual values:

```dart
static const FirebaseOptions web = FirebaseOptions(
  apiKey: 'YOUR_ACTUAL_API_KEY_HERE',           // From firebaseConfig.apiKey
  appId: 'YOUR_ACTUAL_APP_ID_HERE',             // From firebaseConfig.appId
  messagingSenderId: 'YOUR_MESSAGING_SENDER_ID', // From firebaseConfig.messagingSenderId
  projectId: 'YOUR_PROJECT_ID',                 // From firebaseConfig.projectId
  authDomain: 'YOUR_PROJECT_ID.firebaseapp.com', // From firebaseConfig.authDomain
  storageBucket: 'YOUR_PROJECT_ID.appspot.com',  // From firebaseConfig.storageBucket
);
```

### Step 4: Enable Email/Password Authentication
1. In Firebase Console, go to **Authentication**
2. Click **"Get started"** if you haven't set it up
3. Go to **"Sign-in method"** tab
4. Click on **"Email/Password"**
5. Enable it and click **"Save"**

### Step 5: Test
Run your app again and try to sign up/login!

---

## Alternative: Use FlutterFire CLI (Recommended)

If you prefer automatic configuration:

```bash
# 1. Make sure flutterfire is in your PATH
export PATH="$PATH:$HOME/.pub-cache/bin"

# 2. Run configuration
flutterfire configure

# 3. Select your Firebase project
# 4. Select platforms (at least select "web" for Chrome)
```

This will automatically generate the correct `firebase_options.dart` file.

