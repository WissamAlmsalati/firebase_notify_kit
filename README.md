## firebase_notify_kit

`firebase_notify_kit` is a lightweight and modular Firebase Cloud Messaging (FCM) integration kit for Flutter. It simplifies the process of managing push notifications and routing users to specific screens based on the message payload — all while considering authentication status.

### 🚀 Features

- 🔔 Handles foreground, background, and terminated message states
- 🧭 Supports deep linking and screen navigation based on payload data
- ✅ Automatically checks user authentication before routing
- 📲 Saves device tokens via a customizable callback
- 📦 Integrates Flutter Local Notifications for foreground alerts
- 🛠️ Clean, reusable architecture with minimal boilerplate

### 🧩 Use Cases

- Route users to specific screens when they tap on a notification
- Delay navigation until the user is authenticated
- Display local notifications while the app is in the foreground
- Store FCM device tokens securely

### 🛠️ Configuration

You can configure:
- `onNavigate`: Custom function to handle navigation
- `loginRoute`: Screen to navigate to when the user is unauthenticated
- `rootRoute`: Default screen if no deep link is included
- `readAuthToken`: Callback to determine authentication state
- `saveDeviceToken`: Callback to store the FCM token

### 📦 Installation

```yaml
dependencies:
  firebase_notify_kit: ^1.0.0
