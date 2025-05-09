import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:road_helperr/models/help_request.dart';
import 'package:road_helperr/services/help_request_service.dart';
import 'package:road_helperr/ui/screens/ai_welcome_screen.dart';
import 'package:road_helperr/ui/screens/bottomnavigationbar_screes/map_screen.dart';
import 'package:road_helperr/ui/screens/bottomnavigationbar_screes/profile_screen.dart';

import '../../../utils/app_colors.dart';
import 'home_screen.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class NotificationScreen extends StatefulWidget {
  static const String routeName = "notification";

  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  int _selectedIndex = 3; // Removed const since we need to update it

  final HelpRequestService _helpRequestService = HelpRequestService();
  List<Map<String, dynamic>> _notifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  // Cargar notificaciones
  Future<void> _loadNotifications() async {
    try {
      final notifications =
          await _helpRequestService.getHelpRequestNotifications();

      if (mounted) {
        setState(() {
          _notifications = notifications;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading notifications: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Limpiar todas las notificaciones
  Future<void> _clearAllNotifications() async {
    try {
      await _helpRequestService.clearAllNotifications();

      if (mounted) {
        setState(() {
          _notifications = [];
        });
      }
    } catch (e) {
      debugPrint('Error clearing notifications: $e');
    }
  }

  // Eliminar una notificación específica
  Future<void> _removeNotification(String notificationId) async {
    try {
      await _helpRequestService.removeNotification(notificationId);

      if (mounted) {
        setState(() {
          _notifications.removeWhere((notification) {
            final data = notification['data'] as Map<String, dynamic>;
            return data['requestId'] == notificationId;
          });
        });
      }
    } catch (e) {
      debugPrint('Error removing notification: $e');
    }
  }

  // Mostrar diálogo de solicitud de ayuda
  Future<void> _showHelpRequestDialog(
      Map<String, dynamic> notificationData) async {
    try {
      final data = notificationData['data'] as Map<String, dynamic>;

      // Convertir los datos a un objeto HelpRequest
      final request = HelpRequest.fromJson(data);

      // Mostrar el diálogo
      final result =
          await _helpRequestService.showHelpRequestDialog(context, request);

      // Si el usuario respondió a la solicitud, eliminar la notificación
      if (result != null) {
        await _removeNotification(request.requestId);
      }
    } catch (e) {
      debugPrint('Error showing help request dialog: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final platform = Theme.of(context).platform;

    return LayoutBuilder(
      builder: (context, constraints) {
        final size = MediaQuery.of(context).size;
        final isTablet = constraints.maxWidth > 600;
        final isDesktop = constraints.maxWidth > 1200;

        double titleSize = size.width *
            (isDesktop
                ? 0.02
                : isTablet
                    ? 0.03
                    : 0.04);
        double subtitleSize = titleSize * 0.8;
        double iconSize = size.width *
            (isDesktop
                ? 0.02
                : isTablet
                    ? 0.025
                    : 0.03);
        double navBarHeight = size.height *
            (isDesktop
                ? 0.08
                : isTablet
                    ? 0.07
                    : 0.06);
        double spacing = size.height * 0.02;

        return platform == TargetPlatform.iOS ||
                platform == TargetPlatform.macOS
            ? _buildCupertinoLayout(context, size, titleSize, subtitleSize,
                iconSize, navBarHeight, spacing, isDesktop)
            : _buildMaterialLayout(context, size, titleSize, subtitleSize,
                iconSize, navBarHeight, spacing, isDesktop);
      },
    );
  }

  Widget _buildMaterialLayout(
    BuildContext context,
    Size size,
    double titleSize,
    double subtitleSize,
    double iconSize,
    double navBarHeight,
    double spacing,
    bool isDesktop,
  ) {
    var lang = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: Theme.of(context).brightness == Brightness.light
          ? Colors.white
          : const Color(0xFF01122A),
      appBar: AppBar(
        backgroundColor: Theme.of(context).brightness == Brightness.light
            ? Colors.white
            : const Color(0xFF01122A),
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios,
            color: Theme.of(context).brightness == Brightness.light
                ? Colors.black
                : Colors.white,
            size: iconSize,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          lang.noNotifications,
          style: TextStyle(
            color: Theme.of(context).brightness == Brightness.light
                ? Colors.black
                : Colors.white,
            fontSize: titleSize,
          ),
        ),
        actions: [
          TextButton(
            onPressed: _clearAllNotifications,
            child: Text(
              lang.clearAll,
              style: TextStyle(
                color: Theme.of(context).brightness == Brightness.light
                    ? AppColors.getSwitchColor(context)
                    : Colors.white,
                fontSize: subtitleSize,
              ),
            ),
          ),
        ],
      ),
      body: _buildBody(
          context, size, titleSize, subtitleSize, spacing, isDesktop),
      bottomNavigationBar:
          _buildMaterialNavBar(context, iconSize, navBarHeight, isDesktop),
    );
  }

  Widget _buildCupertinoLayout(
    BuildContext context,
    Size size,
    double titleSize,
    double subtitleSize,
    double iconSize,
    double navBarHeight,
    double spacing,
    bool isDesktop,
  ) {
    var lang = AppLocalizations.of(context)!;
    return CupertinoPageScaffold(
      backgroundColor: Theme.of(context).brightness == Brightness.light
          ? Colors.white
          : AppColors.getCardColor(context),
      navigationBar: CupertinoNavigationBar(
        backgroundColor: Theme.of(context).brightness == Brightness.light
            ? Colors.white
            : AppColors.getCardColor(context),
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          child: Icon(
            CupertinoIcons.back,
            color: Theme.of(context).brightness == Brightness.light
                ? Colors.black
                : Colors.white,
            size: iconSize,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        middle: Text(
          lang.noNotifications,
          style: TextStyle(
            color: Theme.of(context).brightness == Brightness.light
                ? Colors.black
                : Colors.white,
            fontSize: titleSize,
            fontFamily: '.SF Pro Text',
          ),
        ),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: _clearAllNotifications,
          child: Text(
            lang.clearAll,
            style: TextStyle(
              color: Theme.of(context).brightness == Brightness.light
                  ? AppColors.getSwitchColor(context)
                  : Colors.white,
              fontSize: subtitleSize,
              fontFamily: '.SF Pro Text',
            ),
          ),
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: _buildBody(
                  context, size, titleSize, subtitleSize, spacing, isDesktop),
            ),
            _buildCupertinoNavBar(context, iconSize, navBarHeight, isDesktop),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    Size size,
    double titleSize,
    double subtitleSize,
    double spacing,
    bool isDesktop,
  ) {
    final platform = Theme.of(context).platform;
    final isIOS =
        platform == TargetPlatform.iOS || platform == TargetPlatform.macOS;
    var lang = AppLocalizations.of(context)!;

    return Center(
      child: Container(
        constraints: BoxConstraints(
          maxWidth: isDesktop ? 800 : 600,
        ),
        padding: EdgeInsets.all(size.width * 0.04),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _notifications.isEmpty
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(height: spacing * 8),
                      Image.asset(
                        Theme.of(context).brightness == Brightness.light
                            ? "assets/images/notification light.png"
                            : "assets/images/Group 12.png",
                        width: size.width * (isDesktop ? 0.3 : 0.5),
                        fit: BoxFit.contain,
                      ),
                      SizedBox(height: spacing * 3),
                      Text(
                        lang.noNotifications,
                        style: TextStyle(
                          color:
                              Theme.of(context).brightness == Brightness.light
                                  ? AppColors.getSwitchColor(context)
                                  : const Color(0xFFA0A0A0),
                          fontSize: titleSize,
                          fontWeight: FontWeight.w600,
                          fontFamily: isIOS ? '.SF Pro Text' : null,
                        ),
                      ),
                      SizedBox(height: spacing * 1.5),
                      Text(
                        lang.notificationInboxEmpty,
                        style: TextStyle(
                          color:
                              Theme.of(context).brightness == Brightness.light
                                  ? AppColors.getSwitchColor(context)
                                  : const Color(0xFFA0A0A0),
                          fontSize: subtitleSize,
                          fontFamily: isIOS ? '.SF Pro Text' : null,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const Spacer(),
                    ],
                  )
                : ListView.builder(
                    itemCount: _notifications.length,
                    itemBuilder: (context, index) {
                      final notification = _notifications[index];
                      final type = notification['type'] as String;
                      final data = notification['data'] as Map<String, dynamic>;

                      // Mostrar diferentes tipos de notificaciones
                      if (type == 'help_request') {
                        return _buildHelpRequestNotification(
                          context,
                          data,
                          titleSize,
                          subtitleSize,
                        );
                      }

                      // Tipo de notificación desconocido
                      return const SizedBox.shrink();
                    },
                  ),
      ),
    );
  }

  // Construir una notificación de solicitud de ayuda
  Widget _buildHelpRequestNotification(
    BuildContext context,
    Map<String, dynamic> data,
    double titleSize,
    double subtitleSize,
  ) {
    final request = HelpRequest.fromJson(data);
    final timestamp = request.timestamp;
    final timeString =
        '${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}';
    final dateString = '${timestamp.day}/${timestamp.month}/${timestamp.year}';

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      elevation: 2,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.getSwitchColor(context),
          child: const Icon(Icons.help_outline, color: Colors.white),
        ),
        title: Text(
          'Help Request from ${request.senderName}',
          style: TextStyle(
            fontSize: titleSize * 0.8,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            if (request.message != null && request.message!.isNotEmpty)
              Text(
                request.message!,
                style: TextStyle(fontSize: subtitleSize * 0.9),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            const SizedBox(height: 4),
            Text(
              '$timeString - $dateString',
              style: TextStyle(
                fontSize: subtitleSize * 0.8,
                color: Colors.grey,
              ),
            ),
          ],
        ),
        trailing: request.status == HelpRequestStatus.pending
            ? const Icon(Icons.arrow_forward_ios, size: 16)
            : null,
        onTap: () => _showHelpRequestDialog(
          {'type': 'help_request', 'data': data},
        ),
      ),
    );
  }

  Widget _buildMaterialNavBar(
    BuildContext context,
    double iconSize,
    double navBarHeight,
    bool isDesktop,
  ) {
    return Container(
      constraints: BoxConstraints(
        maxWidth: isDesktop ? 1200 : double.infinity,
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 0),
        child: CurvedNavigationBar(
        backgroundColor: Theme.of(context).brightness == Brightness.light
            ? Colors.white
            : const Color(0xFF01122A),
        color: Theme.of(context).brightness == Brightness.light
            ? const Color(0xFF023A87)
            : const Color(0xFF1F3551),
        buttonBackgroundColor: Theme.of(context).brightness == Brightness.light
            ? const Color(0xFF023A87)
            : const Color(0xFF1F3551),
        animationDuration: const Duration(milliseconds: 300),
        height: 45,
        index: _selectedIndex,
        letIndexChange: (index) => true,
        items: [
          Icon(Icons.home_outlined, size: iconSize, color: Colors.white),
          Icon(Icons.location_on_outlined, size: iconSize, color: Colors.white),
          Icon(Icons.textsms_outlined, size: iconSize, color: Colors.white),
          Icon(Icons.notifications_outlined,
              size: iconSize, color: Colors.white),
          Icon(Icons.person_2_outlined, size: iconSize, color: Colors.white),
        ],
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
          _handleNavigation(context, index);
        },
      ),
      ),
    );
  }

  Widget _buildCupertinoNavBar(
    BuildContext context,
    double iconSize,
    double navBarHeight,
    bool isDesktop,
  ) {
    var lang = AppLocalizations.of(context)!;
    return Container(
      constraints: BoxConstraints(
        maxWidth: isDesktop ? 1200 : double.infinity,
      ),
      child: CupertinoTabBar(
        backgroundColor: AppColors.getBackgroundColor(context),
        activeColor: Colors.white,
        inactiveColor: Colors.white.withOpacity(0.6),
        height: navBarHeight,
        currentIndex: _selectedIndex,
        items: [
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.home, size: iconSize),
            label: lang.home,
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.location, size: iconSize),
            label: lang.map,
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.chat_bubble, size: iconSize),
            label: lang.chat,
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.bell, size: iconSize),
            label: lang.noNotifications,
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.person, size: iconSize),
            label: lang.profile,
          ),
        ],
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
          _handleNavigation(context, index);
        },
      ),
    );
  }

  void _handleNavigation(BuildContext context, int index) {
    final routes = [
      HomeScreen.routeName,
      MapScreen.routeName,
      AiWelcomeScreen.routeName,
      NotificationScreen.routeName,
      ProfileScreen.routeName,
    ];

    if (index >= 0 && index < routes.length) {
      Navigator.pushReplacementNamed(context, routes[index]);
    }
  }
}
