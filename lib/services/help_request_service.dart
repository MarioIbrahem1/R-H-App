import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:road_helperr/models/help_request.dart';
import 'package:road_helperr/services/api_service.dart';
import 'package:road_helperr/ui/widgets/help_request_dialog.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HelpRequestService {
  static final HelpRequestService _instance = HelpRequestService._internal();
  factory HelpRequestService() => _instance;
  HelpRequestService._internal();

  Timer? _checkRequestsTimer;
  final List<String> _processedRequestIds = [];
  bool _isInitialized = false;

  // Initialize the service
  Future<void> initialize() async {
    if (_isInitialized) return;

    _isInitialized = true;
    _startCheckingRequests();
  }

  // Start checking for new help requests periodically
  void _startCheckingRequests() {
    _checkRequestsTimer?.cancel();
    _checkRequestsTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _checkForNewRequests(),
    );
  }

  // Check for new help requests
  Future<void> _checkForNewRequests() async {
    try {
      final requests = await ApiService.getPendingHelpRequests();

      // Filter out already processed requests
      final newRequests = requests
          .where(
            (request) => !_processedRequestIds.contains(request.requestId),
          )
          .toList();

      // Add new request IDs to processed list
      for (var request in newRequests) {
        _processedRequestIds.add(request.requestId);
      }

      // Limit the size of the processed list to avoid memory issues
      if (_processedRequestIds.length > 100) {
        _processedRequestIds.removeRange(0, _processedRequestIds.length - 100);
      }

      // Show notifications for new requests
      for (var request in newRequests) {
        _showHelpRequestNotification(request);
      }
    } catch (e) {
      debugPrint('Error checking for help requests: $e');
    }
  }

  // Show a notification for a new help request
  Future<void> _showHelpRequestNotification(HelpRequest request) async {
    // Log the notification
    debugPrint('New help request from ${request.senderName}');

    // Save the request to be displayed in the notification screen
    await _saveHelpRequestToNotifications(request);

    // Note: Firebase notifications will be used instead of local notifications
  }

  // Save help request to notifications list
  Future<void> _saveHelpRequestToNotifications(HelpRequest request) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Get existing notifications
      final List<String> notificationIds =
          prefs.getStringList('notification_ids') ?? [];

      // Add the new notification ID if it doesn't exist
      if (!notificationIds.contains(request.requestId)) {
        notificationIds.add(request.requestId);
        await prefs.setStringList('notification_ids', notificationIds);

        // Save the notification data
        await prefs.setString('notification_${request.requestId}',
            '{"type":"help_request","data":${request.toJson().toString().replaceAll('"', '\\"')}}');
      }
    } catch (e) {
      debugPrint('Error saving help request to notifications: $e');
    }
  }

  // Show a help request dialog
  Future<bool?> showHelpRequestDialog(
      BuildContext context, HelpRequest request) {
    return HelpRequestDialog.show(context, request);
  }

  // Get all help request notifications
  Future<List<Map<String, dynamic>>> getHelpRequestNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Get notification IDs
      final List<String> notificationIds =
          prefs.getStringList('notification_ids') ?? [];

      // Get notification data for each ID
      final List<Map<String, dynamic>> notifications = [];

      for (final id in notificationIds) {
        final String? notificationData = prefs.getString('notification_$id');

        if (notificationData != null) {
          try {
            // Parse the notification data
            final Map<String, dynamic> data = Map<String, dynamic>.from(
              Map.castFrom(
                jsonDecode(notificationData.replaceAll('\\"', '"')),
              ),
            );

            notifications.add(data);
          } catch (e) {
            debugPrint('Error parsing notification data: $e');
          }
        }
      }

      return notifications;
    } catch (e) {
      debugPrint('Error getting help request notifications: $e');
      return [];
    }
  }

  // Clear all notifications
  Future<void> clearAllNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Get notification IDs
      final List<String> notificationIds =
          prefs.getStringList('notification_ids') ?? [];

      // Remove all notification data
      for (final id in notificationIds) {
        await prefs.remove('notification_$id');
      }

      // Clear the notification IDs list
      await prefs.setStringList('notification_ids', []);
    } catch (e) {
      debugPrint('Error clearing notifications: $e');
    }
  }

  // Remove a specific notification
  Future<void> removeNotification(String notificationId) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Get notification IDs
      final List<String> notificationIds =
          prefs.getStringList('notification_ids') ?? [];

      // Remove the notification ID from the list
      notificationIds.remove(notificationId);

      // Update the notification IDs list
      await prefs.setStringList('notification_ids', notificationIds);

      // Remove the notification data
      await prefs.remove('notification_$notificationId');
    } catch (e) {
      debugPrint('Error removing notification: $e');
    }
  }

  // Dispose resources
  void dispose() {
    _checkRequestsTimer?.cancel();
    _isInitialized = false;
  }
}
