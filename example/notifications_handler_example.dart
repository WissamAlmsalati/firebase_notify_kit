import 'package:firebase_notify_kit/notifications_handler.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

// Global navigator key for navigation
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final storage = FlutterSecureStorage();

  final config = NotificationServiceConfig(
    onNavigate: (route, payload) {
      navigatorKey.currentState?.pushNamed(route, arguments: payload);
    },
    loginRoute: '/login',
    rootRoute: '/home',
    readAuthToken: () async => await storage.read(key: 'authToken'),
    saveDeviceToken: (token) async =>
        await storage.write(key: 'deviceToken', value: token),
  );

  final notificationService = NotificationService(config);
  await notificationService.initialize();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'Notification Service Example',
      initialRoute: '/login',
      routes: {
        '/login': (_) => const LoginPage(),
        '/home': (_) => const HomePage(),
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

class LoginPage extends StatelessWidget {
  static final _storage = FlutterSecureStorage();
  const LoginPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            LoginPage._storage
                .write(key: 'authToken', value: 'dummy_token')
                .then((_) {
              navigatorKey.currentState?.pushReplacementNamed('/home');
            });
          },
          child: const Text('Log In'),
        ),
      ),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Home')),
      body: ListView(
        children: List.generate(5, (i) => i + 1).map((i) {
          return ListTile(
            title: Text('Item #\$i'),
            onTap: () {
              navigatorKey.currentState?.pushNamed(
                '/details',
                arguments: {'itemId': i},
              );
            },
          );
        }).toList(),
      ),
    );
  }
}

class DetailsPage extends StatelessWidget {
  final String itemId;
  const DetailsPage({Key? key, required this.itemId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Details of Item \$itemId')),
      body: Center(child: Text('Showing details for item \$itemId')),
    );
  }
}
