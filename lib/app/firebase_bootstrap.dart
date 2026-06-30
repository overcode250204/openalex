import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../firebase_options.dart';
import '../services/firebase/cloud_messaging_service.dart';
import '../services/firebase/crashlytics_service.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await FirebaseMessagingBackgroundStore.save(message);
}

class FirebaseBootstrap {
  const FirebaseBootstrap._();

  static Future<void> initialize({
    AppCrashlyticsService? crashlyticsService,
  }) async {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    await (crashlyticsService ?? FirebaseCrashlyticsService()).initialize();
  }
}
