import 'package:flutter/material.dart';

import '../../core/services/connectivity_service.dart';

/// Banner shown when the device is offline
class OfflineBanner extends StatelessWidget {
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: ConnectivityService.instance.isConnected,
      builder: (context, isConnected, child) {
        if (isConnected) return const SizedBox.shrink();
        return MaterialBanner(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          content: const Row(
            children: [
              Icon(Icons.wifi_off, color: Colors.white, size: 18),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Không có kết nối mạng',
                  style: TextStyle(color: Colors.white, fontSize: 13),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.red.shade700,
          actions: const [SizedBox.shrink()],
        );
      },
    );
  }
}
