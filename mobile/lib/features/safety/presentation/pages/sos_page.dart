import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ionicons/ionicons.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../shared/widgets/buttons/app_back_button.dart';

class SosPage extends StatefulWidget {
  const SosPage({super.key});

  @override
  State<SosPage> createState() => _SosPageState();
}

class _SosPageState extends State<SosPage> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  bool _isEmergencyMode = false;
  int _countdown = 5;
  Timer? _countdownTimer;

  // Mock emergency contacts
  final List<Map<String, String>> _emergencyContacts = [
    {'name': 'Bố', 'phone': '0901234567'},
    {'name': 'Mẹ', 'phone': '0901234568'},
  ];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _startEmergency() {
    HapticFeedback.heavyImpact();
    setState(() {
      _isEmergencyMode = true;
      _countdown = 5;
    });

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdown > 1) {
        setState(() => _countdown--);
        HapticFeedback.mediumImpact();
      } else {
        timer.cancel();
        _triggerSos();
      }
    });
  }

  void _cancelEmergency() {
    _countdownTimer?.cancel();
    setState(() {
      _isEmergencyMode = false;
      _countdown = 5;
    });
  }

  Future<void> _triggerSos() async {
    // Show confirmation
    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.error.withAlpha(25),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Ionicons.call_outline,
                  color: AppColors.error,
                  size: 40,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Đang gửi tín hiệu SOS',
                style: AppTypography.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Vị trí của bạn đang được gửi đến các liên hệ khẩn cấp và đội ngũ hỗ trợ.',
                style: AppTypography.bodyMedium.copyWith(
                  color: context.appColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation(AppColors.error),
              ),
            ],
          ),
        ),
      );

      // Simulate sending SOS
      await Future.delayed(const Duration(seconds: 3));

      if (mounted) {
        Navigator.pop(context);
        setState(() => _isEmergencyMode = false);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã gửi tín hiệu SOS thành công'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    }
  }

  Future<void> _callEmergency(String number) async {
    final uri = Uri(scheme: 'tel', path: number);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _isEmergencyMode ? AppColors.error : context.appColors.background,
      appBar: AppBar(
        leading: const AppBackButton(),
        title: const Text('SOS Khẩn cấp'),
        backgroundColor: _isEmergencyMode ? AppColors.error : null,
        foregroundColor: _isEmergencyMode ? AppColors.textWhite : null,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // Info Banner
              if (!_isEmergencyMode)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withAlpha(25),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.warning.withAlpha(50)),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Ionicons.alert_circle_outline,
                        color: AppColors.warning,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Chỉ sử dụng khi bạn gặp nguy hiểm thực sự',
                          style: AppTypography.bodySmall.copyWith(
                            color: context.appColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              const Spacer(),

              // SOS Button
              GestureDetector(
                onLongPress: _isEmergencyMode ? null : _startEmergency,
                onLongPressEnd: _isEmergencyMode ? null : (_) => _cancelEmergency(),
                child: AnimatedBuilder(
                  animation: _pulseAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _isEmergencyMode ? _pulseAnimation.value : 1.0,
                      child: Container(
                        width: 200,
                        height: 200,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.error,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.error.withAlpha(100),
                              blurRadius: _isEmergencyMode ? 40 : 20,
                              spreadRadius: _isEmergencyMode ? 10 : 0,
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (_isEmergencyMode) ...[
                              Text(
                                '$_countdown',
                                style: AppTypography.displayLarge.copyWith(
                                  color: AppColors.textWhite,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'Nhả để hủy',
                                style: AppTypography.labelMedium.copyWith(
                                  color: AppColors.textWhite.withAlpha(200),
                                ),
                              ),
                            ] else ...[
                              const Icon(
                                Ionicons.alert_circle_outline,
                                color: AppColors.textWhite,
                                size: 48,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'SOS',
                                style: AppTypography.headlineLarge.copyWith(
                                  color: AppColors.textWhite,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 24),

              Text(
                _isEmergencyMode
                    ? 'Nhả tay để hủy'
                    : 'Giữ nút để kích hoạt SOS',
                style: AppTypography.bodyLarge.copyWith(
                  color: _isEmergencyMode
                      ? AppColors.textWhite
                      : context.appColors.textSecondary,
                ),
              ),

              const Spacer(),

              // Quick Actions
              if (!_isEmergencyMode) ...[
                Text(
                  'Gọi nhanh',
                  style: AppTypography.titleSmall.copyWith(
                    color: context.appColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _QuickCallButton(
                      icon: Ionicons.call_outline,
                      label: '113',
                      subtitle: 'Công an',
                      color: AppColors.error,
                      onTap: () => _callEmergency('113'),
                    ),
                    _QuickCallButton(
                      icon: Ionicons.business_outline,
                      label: '115',
                      subtitle: 'Cấp cứu',
                      color: AppColors.info,
                      onTap: () => _callEmergency('115'),
                    ),
                    _QuickCallButton(
                      icon: Ionicons.flash_outline,
                      label: '114',
                      subtitle: 'Cứu hỏa',
                      color: AppColors.warning,
                      onTap: () => _callEmergency('114'),
                    ),
                  ],
                ),

                const SizedBox(height: 32),

                // Emergency Contacts
                if (_emergencyContacts.isNotEmpty) ...[
                  Text(
                    'Liên hệ khẩn cấp',
                    style: AppTypography.titleSmall.copyWith(
                      color: context.appColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: context.appColors.card,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: context.appColors.border),
                    ),
                    child: Column(
                      children: _emergencyContacts.map((contact) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: context.appColors.background,
                                  shape: BoxShape.circle,
                                ),
                                child:   Icon(
                                  Ionicons.person_outline,
                                  color: context.appColors.textSecondary,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      contact['name']!,
                                      style: AppTypography.bodyMedium,
                                    ),
                                    Text(
                                      contact['phone']!,
                                      style: AppTypography.labelSmall.copyWith(
                                        color: context.appColors.textHint,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                onPressed: () => _callEmergency(contact['phone']!),
                                icon: const Icon(
                                  Ionicons.call_outline,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ],

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickCallButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _QuickCallButton({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: color.withAlpha(25),
              shape: BoxShape.circle,
              border: Border.all(color: color.withAlpha(50)),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: AppTypography.titleMedium.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            subtitle,
            style: AppTypography.labelSmall.copyWith(
              color: context.appColors.textHint,
            ),
          ),
        ],
      ),
    );
  }
}
