import 'package:road_helperr/ui/screens/bottomnavigationbar_screes/notification_screen.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

// تعريف مفتاح التنقل العام للتطبيق
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class FirebaseNotification {
  late final FirebaseMessaging _firebaseMessaging;

  Future<void> initNotification() async {
    try {
      // تهيئة FirebaseMessaging
      _firebaseMessaging = FirebaseMessaging.instance;

      // طلب إذن الإشعارات
      await _firebaseMessaging.requestPermission();
      String? token = await _firebaseMessaging.getToken();
      // استخدام debugPrint بدلاً من print للتسجيل في وضع التطوير فقط
      debugPrint("FCM Token: $token");

      handleBackGroundNotification();
    } catch (e) {
      debugPrint("خطأ في تهيئة الإشعارات: $e");
    }
  }

  void handleMessage(RemoteMessage? message) {
    if (message == null) return;
    navigatorKey.currentState!
        .pushNamed(NotificationScreen.routeName, arguments: message);
  }

  Future<void> handleBackGroundNotification() async {
    try {
      // معالجة الإشعارات عند فتح التطبيق من خلال الإشعار
      FirebaseMessaging.instance.getInitialMessage().then(handleMessage);

      // معالجة الإشعارات عندما يكون التطبيق في الخلفية
      FirebaseMessaging.onMessageOpenedApp.listen(handleMessage);
    } catch (e) {
      debugPrint("خطأ في إعداد معالجة الإشعارات: $e");
    }
  }
}
