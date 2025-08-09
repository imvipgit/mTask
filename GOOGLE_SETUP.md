# Google Tasks Integration Setup Guide

This guide will help you set up Google Tasks integration for mTask. This requires creating a Google Cloud project and configuring OAuth credentials.

## Prerequisites

- Google account
- Access to [Google Cloud Console](https://console.cloud.google.com/)
- Xcode project with mTask

## Step 1: Create a Google Cloud Project

1. Go to the [Google Cloud Console](https://console.cloud.google.com/)
2. Click "Select a project" at the top
3. Click "New Project"
4. Enter project name: "mTask Integration"
5. Click "Create"

## Step 2: Enable Google Tasks API

1. In your Google Cloud project, go to "APIs & Services" > "Library"
2. Search for "Google Tasks API"
3. Click on "Google Tasks API"
4. Click "Enable"

## Step 3: Configure OAuth Consent Screen

1. Go to "APIs & Services" > "OAuth consent screen"
2. Select "External" user type
3. Click "Create"
4. Fill in the required information:
   - **App name**: mTask
   - **User support email**: Your email
   - **Developer contact information**: Your email
5. Click "Save and Continue"
6. On the "Scopes" page, click "Save and Continue"
7. On the "Test users" page, add your email address
8. Click "Save and Continue"

## Step 4: Create OAuth Credentials

1. Go to "APIs & Services" > "Credentials"
2. Click "Create Credentials" > "OAuth client ID"
3. Select "macOS" as the application type
4. Enter name: "mTask macOS App"
5. Enter bundle identifier: `com.mtask.app` (or your chosen bundle ID)
6. Click "Create"
7. **Important**: Copy the "Client ID" - you'll need this for your app

## Step 5: Configure Your App

1. Open your mTask project in Xcode
2. Open `mTask/Sync/AuthManager.swift`
3. Replace `YOUR_GOOGLE_CLIENT_ID` with your actual client ID:

```swift
struct OAuthConfig {
    static let clientId = "YOUR_ACTUAL_CLIENT_ID_HERE"
    // ... rest of the configuration
}
```

## Step 6: Configure URL Scheme

1. In Xcode, select your project in the navigator
2. Select the mTask target
3. Go to the "Info" tab
4. Expand "URL Types"
5. Click "+" to add a new URL type
6. Set the following:
   - **Identifier**: `com.mtask.app.oauth`
   - **URL Schemes**: `com.mtask.app`
   - **Role**: Editor

## Step 7: Update Info.plist (if needed)

Add the following to your `Info.plist` if not already present:

```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleURLName</key>
        <string>com.mtask.app.oauth</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>com.mtask.app</string>
        </array>
    </dict>
</array>
```

## Step 8: Test the Integration

1. Build and run your app
2. Go to the sidebar and click the cloud icon
3. Click "Sign in with Google"
4. Complete the OAuth flow in your browser
5. You should see "Connected to Google Tasks" in the sync view
6. Try creating a task and syncing to see it appear in Google Tasks

## Security Notes

- **Never commit your client ID to public repositories**
- Consider using environment variables or configuration files for sensitive data
- The client ID in this setup is for development only
- For production distribution, you may need to verify your app with Google

## Troubleshooting

### "Redirect URI mismatch" error
- Ensure the URL scheme in Xcode matches what you configured in Google Cloud Console
- The redirect URI should be `com.mtask.app://oauth`

### "This app hasn't been verified by Google"
- This is normal during development
- Click "Advanced" and then "Go to mTask (unsafe)" for testing
- For production, you'll need to go through Google's verification process

### "Access blocked" error
- Make sure you added your email as a test user in the OAuth consent screen
- Ensure the Google Tasks API is enabled

### Sync not working
- Check that you have a valid internet connection
- Verify your client ID is correctly set in `AuthManager.swift`
- Check the app logs for any API errors

## API Limits

- Google Tasks API has generous limits for personal use
- For production apps with many users, review Google's quotas and pricing
- Consider implementing proper error handling and retry logic

## Next Steps

Once Google Tasks integration is working:

1. Test creating, updating, and deleting tasks
2. Test creating and managing task lists
3. Verify bidirectional sync works correctly
4. Test conflict resolution when the same task is modified in both places
5. Consider implementing offline support improvements

## Support

If you encounter issues:

1. Check the [Google Tasks API documentation](https://developers.google.com/tasks)
2. Review the [Google Cloud Console help](https://cloud.google.com/support)
3. Check the mTask GitHub repository for issues and discussions
