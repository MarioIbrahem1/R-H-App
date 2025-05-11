import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class UpdateInfo {
  final String version;
  final int versionCode;
  final String downloadUrl;
  final String releaseNotes;
  final bool forceUpdate;

  UpdateInfo({
    required this.version,
    required this.versionCode,
    required this.downloadUrl,
    required this.releaseNotes,
    this.forceUpdate = false,
  });

  factory UpdateInfo.fromJson(Map<String, dynamic> json) {
    return UpdateInfo(
      version: json['version'] ?? '',
      versionCode: json['versionCode'] ?? 0,
      downloadUrl: json['downloadUrl'] ?? '',
      releaseNotes: json['releaseNotes'] ?? '',
      forceUpdate: json['forceUpdate'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'version': version,
      'versionCode': versionCode,
      'downloadUrl': downloadUrl,
      'releaseNotes': releaseNotes,
      'forceUpdate': forceUpdate,
    };
  }
}

class UpdateService {
  // Singleton instance
  static final UpdateService _instance = UpdateService._internal();
  factory UpdateService() => _instance;

  UpdateService._internal();

  // حفظ معلومات التحديث في التخزين المحلي
  Future<void> saveUpdateInfo(UpdateInfo updateInfo) async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('update_version', updateInfo.version);
      await prefs.setInt('update_version_code', updateInfo.versionCode);
      await prefs.setString('update_download_url', updateInfo.downloadUrl);
      await prefs.setString('update_release_notes', updateInfo.releaseNotes);
      await prefs.setBool('update_force_update', updateInfo.forceUpdate);
      await prefs.setBool('update_available', true);
    } catch (e) {
      debugPrint('خطأ في حفظ معلومات التحديث: $e');
    }
  }

  // الحصول على معلومات التحديث من التخزين المحلي
  Future<UpdateInfo?> getUpdateInfo() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final bool updateAvailable = prefs.getBool('update_available') ?? false;

      if (!updateAvailable) {
        return null;
      }

      return UpdateInfo(
        version: prefs.getString('update_version') ?? '',
        versionCode: prefs.getInt('update_version_code') ?? 0,
        downloadUrl: prefs.getString('update_download_url') ?? '',
        releaseNotes: prefs.getString('update_release_notes') ?? '',
        forceUpdate: prefs.getBool('update_force_update') ?? false,
      );
    } catch (e) {
      debugPrint('خطأ في الحصول على معلومات التحديث: $e');
      return null;
    }
  }

  // التحقق من وجود تحديثات وعرض مربع حوار للمستخدم
  Future<void> checkForUpdatesWithDialog(BuildContext context) async {
    try {
      final UpdateInfo? updateInfo = await getUpdateInfo();

      if (updateInfo != null) {
        if (context.mounted) {
          // عرض مربع حوار للمستخدم
          showUpdateDialog(context, updateInfo);
        }
      }
    } catch (e) {
      debugPrint('خطأ في التحقق من التحديثات: $e');
    }
  }

  // عرض مربع حوار التحديث
  void showUpdateDialog(BuildContext context, UpdateInfo updateInfo) {
    showDialog(
      context: context,
      barrierDismissible: !updateInfo.forceUpdate,
      builder: (context) => AlertDialog(
        title: const Text('تحديث جديد متاح'),
        content:
            Text('هناك إصدار جديد من التطبيق متاح (${updateInfo.version}).\n\n'
                '${updateInfo.releaseNotes}\n\n'
                'هل ترغب في التحديث الآن؟'),
        actions: [
          if (!updateInfo.forceUpdate)
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('لاحقاً'),
            ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _showDownloadDialog(context, updateInfo);
            },
            child: const Text('تحديث الآن'),
          ),
        ],
      ),
    );
  }

  // عرض مربع حوار التنزيل
  void _showDownloadDialog(BuildContext context, UpdateInfo updateInfo) {
    double progress = 0;
    bool isDownloading = true;
    String statusText = 'جاري تنزيل التحديث...';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('تنزيل التحديث'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(statusText),
                const SizedBox(height: 16),
                LinearProgressIndicator(value: progress),
                Text('${(progress * 100).toStringAsFixed(0)}%'),
              ],
            ),
            actions: [
              if (!isDownloading)
                TextButton(
                  onPressed: () {
                    Navigator.of(dialogContext).pop();
                  },
                  child: const Text('إغلاق'),
                ),
            ],
          );
        },
      ),
    );

    // بدء تنزيل التحديث
    downloadUpdate(
      updateInfo,
      (newProgress) {
        // تحديث شريط التقدم
        if (context.mounted) {
          (context as Element).markNeedsBuild();
          progress = newProgress;
          if (progress >= 1.0) {
            statusText = 'اكتمل التنزيل. جاري فتح المثبت...';
            isDownloading = false;
          }
        }
      },
      onError: (error) {
        if (context.mounted) {
          (context as Element).markNeedsBuild();
          statusText = 'حدث خطأ: $error';
          isDownloading = false;
        }
      },
    );
  }

  // تنزيل التحديث
  Future<void> downloadUpdate(
    UpdateInfo updateInfo,
    Function(double) onProgress, {
    Function(String)? onError,
  }) async {
    try {
      // طلب الأذونات اللازمة
      final status = await Permission.storage.request();
      if (!status.isGranted) {
        const error = 'تم رفض أذونات التخزين';
        if (onError != null) onError(error);
        return;
      }

      // تنزيل الملف
      final http.Client client = http.Client();
      final http.Request request =
          http.Request('GET', Uri.parse(updateInfo.downloadUrl));
      final http.StreamedResponse response = await client.send(request);

      final int totalBytes = response.contentLength ?? 0;
      int receivedBytes = 0;

      if (response.statusCode == 200) {
        final List<int> bytes = [];

        response.stream.listen(
          (List<int> newBytes) {
            bytes.addAll(newBytes);
            receivedBytes += newBytes.length;
            onProgress(totalBytes > 0 ? receivedBytes / totalBytes : 0);
          },
          onDone: () async {
            client.close();

            // فتح المتصفح لتنزيل التحديث
            final Uri uri = Uri.parse(updateInfo.downloadUrl);
            if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
              if (onError != null) onError('فشل في فتح رابط التحديث');
            }
          },
          onError: (e) {
            client.close();
            if (onError != null) onError(e.toString());
          },
          cancelOnError: true,
        );
      } else {
        client.close();
        final error = 'فشل في تنزيل التحديث: ${response.statusCode}';
        if (onError != null) onError(error);
      }
    } catch (e) {
      debugPrint('خطأ في تنزيل التحديث: $e');
      if (onError != null) onError(e.toString());
    }
  }

  // مسح معلومات التحديث
  Future<void> clearUpdateInfo() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setBool('update_available', false);
    } catch (e) {
      debugPrint('خطأ في مسح معلومات التحديث: $e');
    }
  }
}
