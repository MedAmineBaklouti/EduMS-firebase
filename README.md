# edums

## Educational Assistant (Gemini) Setup

The project ships with an Educational Assistant chat powered by Google Gemini and integrated with Firebase. Follow the steps below to configure it for your environment.

### 1. Firebase services

1. Enable **Authentication** (Email/Password or other providers you support).
2. Enable **Cloud Firestore** in production mode.
3. Review and deploy the Firestore rules in [`firestore.rules`](firestore.rules) to restrict access so users can only read/write their own `users/{uid}/eduChats/**` documents.

### 2. Cloud Functions (Gemini proxy)

1. Install dependencies and build the callable function:
   ```bash
   cd functions
   npm install
   firebase functions:config:set genai.key="YOUR_GEMINI_API_KEY"
   npm run build
   ```
2. Deploy the function:
   ```bash
   firebase deploy --only functions
   ```
   The callable endpoint is exposed as `generateEducationalReply` and proxies requests to Gemini with rate limiting and topic filtering.

### 3. Flutter application

1. Ensure the following packages are listed in `pubspec.yaml` (already added):
   - `cloud_firestore`
   - `firebase_auth`
   - `cloud_functions`
   - `get`
   - `intl`
2. Register the new route in your `GetMaterialApp` using `AppPages.routes` (already wired) and ensure the sidebar “Ask something” button is visible for authenticated users.
3. The educational assistant UI lives under `lib/modules/edu_chat/` and streams chat history from Firestore in real time.

### 4. Testing the experience

- Use the sidebar button **Ask something** to open the assistant.
- Try educational prompts such as “Explain recursion with a simple Dart example.”
- Non-educational prompts (e.g., “Who is Messi?”) will politely receive the refusal message required by policy.

### 5. Environment reminders

- The callable function requires the environment variable `functions.config().genai.key` to be set before deployment.
- Rate limiting is enforced server-side (20 requests per user per 5 minutes). Hitting the limit will surface a friendly throttling response in the chat.
