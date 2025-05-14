import 'package:firebase_notify_kit/notifications_handler.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

// A global navigator key to allow navigation from NotificationService
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Secure storage instance for auth & device tokens
  final storage = FlutterSecureStorage();

  // Configure the notification service
  final config = NotificationServiceConfig(
    onNavigate: (route, payload) {
      // Use navigatorKey to push named routes
      navigatorKey.currentState?.pushNamed(route, arguments: payload);
    },
    loginRoute: '/login', // Route name for login screen
    rootRoute: '/home', // Default route after auth
    readAuthToken: () async => await storage.read(key: 'authToken'),
    saveDeviceToken: (token) async =>
        await storage.write(key: 'deviceToken', value: token),
  );

  // Initialize the service
  final notificationService = NotificationService(config);
  await notificationService.initialize();

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Notification Service Example',
      navigatorKey: navigatorKey,
      initialRoute: '/login',
      routes: {
        '/login': (_) => LoginPage(),
        '/home': (_) => HomePage(),
        '/details': (ctx) {
          final args =
              ModalRoute.of(ctx)!.settings.arguments as Map<String, dynamic>?;
          final id = args?['itemId']?.toString() ?? 'unknown';
          return DetailsPage(itemId: id);
        },
      },
    );
  }
}

/// Simple login page: on success, write a token and go to /home
class LoginPage extends StatelessWidget {
  final _storage = FlutterSecureStorage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Login')),
      body: Center(
        child: ElevatedButton(
          onPressed: () async {
            // Simulate login
            await _storage.write(key: 'authToken', value: 'dummy_token');
            Navigator.pushReplacementNamed(context, '/home');
          },
          child: Text('Log In'),
        ),
      ),
    );
  }
}

/// Home page: lists items and can trigger a mock notification
class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Home')),
      body: ListView(
        children: List.generate(5, (i) => i + 1).map((i) {
          return ListTile(
            title: Text('Item #$i'),
            onTap: () {
              Navigator.pushNamed(context, '/details',
                  arguments: {'itemId': i});
            },
          );
        }).toList(),
      ),
    );
  }
}

/// Details page that reads an itemId from payload
class DetailsPage extends StatelessWidget {
  final String itemId;
  DetailsPage({required this.itemId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Details of Item $itemId')),
      body: Center(child: Text('Showing details for item $itemId')),
    );
  }
}
