# Google OAuth Setup Guide for Supabase

This guide will help you configure Google OAuth in your Supabase project to enable Google Sign-In in your Flutter app.

## Step 1: Create Google OAuth Credentials

### 1.1 Go to Google Cloud Console
1. Visit [Google Cloud Console](https://console.cloud.google.com/)
2. Select your project or create a new one
3. Navigate to **APIs & Services** → **Credentials**

### 1.2 Create OAuth 2.0 Client ID
1. Click **Create Credentials** → **OAuth client ID**
2. If prompted, configure the OAuth consent screen first:
   - Choose **External** (unless you have a Google Workspace account)
   - Fill in the required fields (App name, User support email, Developer contact)
   - Add your email to test users if needed
   - Save and continue through the scopes and test users screens

3. Create OAuth Client ID:
   - **Application type**: Select **Web application**
   - **Name**: Give it a name (e.g., "Fitness App Web Client")
   - **Authorized redirect URIs**: Add the following:
     ```
     https://xioqakilrqzabszabxoz.supabase.co/auth/v1/callback
     ```
   - Click **Create**
   - **IMPORTANT**: Copy the **Client ID** and **Client Secret** - you'll need these for Supabase

### 1.3 (Optional) Create Additional Client IDs
If you want separate client IDs for Android/iOS:
- Create an **Android** OAuth client ID (requires package name and SHA-1)
- Create an **iOS** OAuth client ID (requires bundle ID)

For this setup, the Web application client ID is sufficient.

## Step 2: Configure Supabase

### 2.1 Enable Google Provider
1. Go to your [Supabase Dashboard](https://app.supabase.com/)
2. Select your project: **xioqakilrqzabszabxoz**
3. Navigate to **Authentication** → **Providers**
4. Find **Google** in the list and click on it
5. **Toggle "Enable Google provider"** to ON

### 2.2 Add OAuth Credentials
In the Google provider settings:
1. **Client ID (for OAuth)**: Paste your Google OAuth Client ID
   - Example: `978327309093-bsj67n61iatt5emc4egglkhf434hincr.apps.googleusercontent.com`

2. **Client Secret (for OAuth)**: Paste your Google OAuth Client Secret
   - This is the secret key you copied from Google Cloud Console
   - ⚠️ **This is required!** The error "missing OAuth secret" occurs when this is empty

3. Click **Save**

### 2.3 Configure Redirect URLs
1. Go to **Authentication** → **URL Configuration**
2. Under **Redirect URLs**, make sure these are added:
   - `io.supabase.flutter://callback` (for mobile app)
   - `https://xioqakilrqzabszabxoz.supabase.co/auth/v1/callback` (for web, if needed)

3. Under **Site URL**, ensure your app's URL is set correctly

## Step 3: Verify Google Cloud Console Settings

### 3.1 Authorized Redirect URIs
In Google Cloud Console, make sure your OAuth client has these redirect URIs:
- `https://xioqakilrqzabszabxoz.supabase.co/auth/v1/callback`

### 3.2 OAuth Consent Screen
- Make sure your OAuth consent screen is published (or in testing mode with test users added)
- For production, you'll need to submit for verification

## Step 4: Test the Configuration

1. Run your Flutter app
2. Tap "Sign in with Google"
3. You should be redirected to Google's sign-in page
4. After signing in, you should be redirected back to your app
5. The user should be authenticated

## Troubleshooting

### Error: "missing OAuth secret"
- **Solution**: Make sure you've added the Client Secret in Supabase dashboard under Google provider settings

### Error: "Unacceptable audience in id_token"
- **Solution**: This should be resolved by using Supabase's OAuth redirect flow (which we've implemented)

### Error: "redirect_uri_mismatch"
- **Solution**: Make sure the redirect URI in Google Cloud Console matches exactly: `https://xioqakilrqzabszabxoz.supabase.co/auth/v1/callback`

### OAuth consent screen not configured
- **Solution**: Complete the OAuth consent screen setup in Google Cloud Console before creating OAuth credentials

## Important Notes

1. **Client Secret Security**: Never commit your Client Secret to version control. It should only be stored in Supabase dashboard.

2. **Testing**: If your OAuth consent screen is in "Testing" mode, you'll need to add test user emails in Google Cloud Console.

3. **Production**: For production apps, you'll need to:
   - Submit your OAuth consent screen for verification
   - Add your production domain to authorized domains
   - Complete the verification process with Google

4. **Redirect URLs**: The redirect URLs in Supabase and Google Cloud Console must match exactly (including protocol, domain, and path).

## Quick Checklist

- [ ] Created OAuth 2.0 Client ID in Google Cloud Console
- [ ] Copied Client ID and Client Secret
- [ ] Added redirect URI to Google Cloud Console
- [ ] Enabled Google provider in Supabase
- [ ] Added Client ID to Supabase
- [ ] Added Client Secret to Supabase (⚠️ This is the key step!)
- [ ] Added redirect URLs in Supabase URL Configuration
- [ ] Tested the sign-in flow

## Support

If you continue to have issues:
1. Check Supabase logs: **Logs** → **Auth Logs**
2. Check Google Cloud Console for any errors
3. Verify all URLs match exactly (no trailing slashes, correct protocol)
4. Ensure OAuth consent screen is properly configured
















