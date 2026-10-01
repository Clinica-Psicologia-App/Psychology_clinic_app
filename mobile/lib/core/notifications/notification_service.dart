import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart' show Color;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Handler de background — precisa ser top-level (fora de qualquer classe).
@pragma('vm:entry-point')
Future<void> _backgroundMessageHandler(RemoteMessage message) async {
  // Android exibe automaticamente mensagens com notification payload.
  // Não é necessário fazer nada aqui para o MVP.
}

/// Serviço de notificações push: configura FCM e notificações locais.
///
/// Inicializado uma vez em [main] antes do [runApp]. Expõe [tokenStream]
/// para que o restante do app registre o token no Supabase.
abstract final class NotificationService {
  static final _localNotifications = FlutterLocalNotificationsPlugin();

  static const _androidChannel = AndroidNotificationChannel(
    'esquemacore_default',
    'EsquemaCore',
    description: 'Notificações do EsquemaCore',
    importance: Importance.high,
  );

  static Stream<String> get tokenStream =>
      FirebaseMessaging.instance.onTokenRefresh;

  static Future<void> initialize() async {
    // Registra o handler de background antes de qualquer outra coisa.
    FirebaseMessaging.onBackgroundMessage(_backgroundMessageHandler);

    // Cria canal Android (necessário para Android 8+).
    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_androidChannel);

    // Inicializa flutter_local_notifications.
    const initSettings = InitializationSettings(
      android: AndroidInitializationSettings('ic_notification'),
    );
    await _localNotifications.initialize(initSettings);

    // Solicita permissão (Android 13+ / iOS).
    await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // Exibe notificação local quando o app está em foreground.
    FirebaseMessaging.onMessage.listen(_showForegroundNotification);
  }

  static Future<String?> getToken() =>
      FirebaseMessaging.instance.getToken();

  static Future<void> deleteToken() =>
      FirebaseMessaging.instance.deleteToken();

  static void _showForegroundNotification(RemoteMessage message) {
    final n = message.notification;
    if (n == null) return;

    _localNotifications.show(
      message.hashCode,
      n.title,
      n.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _androidChannel.id,
          _androidChannel.name,
          channelDescription: _androidChannel.description,
          importance: Importance.high,
          priority: Priority.high,
          icon: 'ic_notification',
          color: Color(0xFF00B2A9),
        ),
      ),
    );
  }
}
