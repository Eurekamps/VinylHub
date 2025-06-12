// lib/Services/NotificationService.dart

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:googleapis_auth/auth_io.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() => _instance;

  NotificationService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
  FlutterLocalNotificationsPlugin();

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'canal_mensajes',
    'Mensajes',
    description: 'Canal para notificaciones de mensajes',
    importance: Importance.high,
  );

  static const String _serviceAccountAssetPath = 'assets/hijos-de-fluttarkia-2d60dbd18ab5.json';

  static const List<String> _scopes = [
    'https://www.googleapis.com/auth/firebase.messaging'
  ];


  static Future<String> _getAccessToken() async {
    final jsonStr = await rootBundle.loadString(_serviceAccountAssetPath);
    final jsonCredentials = jsonDecode(jsonStr);
    final accountCredentials = ServiceAccountCredentials.fromJson(jsonCredentials);
    final client = await clientViaServiceAccount(accountCredentials, _scopes);
    final token = client.credentials.accessToken.data;
    client.close();
    return token;
  }

  static Future<void> sendPushNotification({
    required String token,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    try {
      final accessToken = await _getAccessToken();
      const projectId = 'hijos-de-fluttarkia';

      final url =
          'https://fcm.googleapis.com/v1/projects/$projectId/messages:send';

      final message = {
        "message": {
          "token": token,
          "notification": {"title": title, "body": body},
          if (data != null && data.isNotEmpty) "data": data,
        }
      };

      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode(message),
      );

      if (response.statusCode == 200) {
        print('✅ Notificación enviada correctamente');
      } else {
        print('❌ Error al enviar notificación: ${response.statusCode}');
        print('🔎 Respuesta: ${response.body}');
      }
    } catch (e) {
      print('🚨 Excepción al enviar notificación: $e');
    }
  }

  Future<void> init() async {
    await _messaging.requestPermission();
    await _initLocalNotifications();
    _listenForeground();
  }

  Future<void> _initLocalNotifications() async {
    const AndroidInitializationSettings androidInitSettings =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initSettings =
    InitializationSettings(android: androidInitSettings);

    await _localNotifications.initialize(initSettings);

    await _localNotifications
        .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);
  }

  void _listenForeground() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _showNotification(message);
    });
  }

  Future<void> showNotificationFromBackground(RemoteMessage message) async {
    await Firebase.initializeApp();
    _showNotification(message);
  }

  void _showNotification(RemoteMessage message) {
    final notification = message.notification;
    if (notification == null) return;

    final androidDetails = AndroidNotificationDetails(
      _channel.id,
      _channel.name,
      channelDescription: _channel.description,
      importance: Importance.max,
      priority: Priority.high,
    );

    final details = NotificationDetails(android: androidDetails);

    _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      notification.title,
      notification.body,
      details,
    );
  }
}

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  NotificationService().showNotificationFromBackground(message);
}
