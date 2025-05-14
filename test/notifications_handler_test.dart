import 'dart:convert';
import 'package:firebase_notify_kit/notifications_handler.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('NotificationService.handlePayload', () {
    test('navigates to login when not authenticated', () {
      final calls = <Map<String, dynamic>>[];
      final config = NotificationServiceConfig(
        onNavigate: (route, payload) =>
            calls.add({'route': route, 'payload': payload}),
        loginRoute: '/login',
        rootRoute: '/home',
        readAuthToken: () async => null,
        saveDeviceToken: (_) async {},
      );
      final svc = NotificationService(config);

      svc.handlePayload('{}');

      expect(calls.length, 1);
      expect(calls[0]['route'], '/login');
      expect((calls[0]['payload'] as Map).isEmpty, isTrue);
    });

    test('navigates to root when authenticated and no screen', () async {
      final calls = <Map<String, dynamic>>[];
      final config = NotificationServiceConfig(
        onNavigate: (route, payload) =>
            calls.add({'route': route, 'payload': payload}),
        loginRoute: '/login',
        rootRoute: '/home',
        readAuthToken: () async => 'token',
        saveDeviceToken: (_) async {},
      );
      final svc = NotificationService(config);

      svc.handlePayload('{}');

      expect(calls.length, 1);
      expect(calls[0]['route'], '/home');
      expect((calls[0]['payload'] as Map).isEmpty, isTrue);
    });

    test('navigates to given screen when authenticated', () {
      final calls = <Map<String, dynamic>>[];
      final config = NotificationServiceConfig(
        onNavigate: (route, payload) =>
            calls.add({'route': route, 'payload': payload}),
        loginRoute: '/login',
        rootRoute: '/home',
        readAuthToken: () async => 'token',
        saveDeviceToken: (_) async {},
      );
      final svc = NotificationService(config);

      final payload = {'screen': 'details', 'itemId': 42};
      svc.handlePayload(json.encode(payload));

      expect(calls.length, 1);
      expect(calls[0]['route'], 'details');
      expect(calls[0]['payload'], payload);
    });
  });
}
