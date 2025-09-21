// lib/widgets/network_status_indicator.dart
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class NetworkStatusIndicator extends StatelessWidget {
  final ConnectivityResult connectivity;
  final int quality; // 1-5 scale

  const NetworkStatusIndicator({
    super.key,
    required this.connectivity,
    required this.quality,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _getBackgroundColor(),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _getBorderColor(), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_getConnectivityIcon(), color: _getIconColor(), size: 14),
          const SizedBox(width: 4),
          Text(
            _getConnectivityText(),
            style: TextStyle(
              color: _getTextColor(),
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 4),
          _buildQualityIndicator(),
        ],
      ),
    );
  }

  Color _getBackgroundColor() {
    if (connectivity == ConnectivityResult.none) {
      return Colors.red.withOpacity(0.9);
    }
    if (quality <= 2) {
      return Colors.orange.withOpacity(0.9);
    }
    return Colors.black.withOpacity(0.6);
  }

  Color _getBorderColor() {
    if (connectivity == ConnectivityResult.none) {
      return Colors.red;
    }
    if (quality <= 2) {
      return Colors.orange;
    }
    return Colors.white.withOpacity(0.3);
  }

  IconData _getConnectivityIcon() {
    switch (connectivity) {
      case ConnectivityResult.wifi:
        return Icons.wifi;
      case ConnectivityResult.mobile:
        return Icons.signal_cellular_alt;
      case ConnectivityResult.ethernet:
        return Icons.settings_ethernet;
      case ConnectivityResult.vpn:
        return Icons.vpn_lock;
      case ConnectivityResult.none:
        return Icons.signal_wifi_off;
      default:
        return Icons.signal_wifi_statusbar_null;
    }
  }

  Color _getIconColor() {
    if (connectivity == ConnectivityResult.none) {
      return Colors.white;
    }
    if (quality <= 2) {
      return Colors.white;
    }
    return Colors.white.withOpacity(0.9);
  }

  String _getConnectivityText() {
    switch (connectivity) {
      case ConnectivityResult.wifi:
        return 'WiFi';
      case ConnectivityResult.mobile:
        return 'Mobile';
      case ConnectivityResult.ethernet:
        return 'Ethernet';
      case ConnectivityResult.vpn:
        return 'VPN';
      case ConnectivityResult.none:
        return 'Offline';
      default:
        return 'Unknown';
    }
  }

  Color _getTextColor() {
    if (connectivity == ConnectivityResult.none) {
      return Colors.white;
    }
    if (quality <= 2) {
      return Colors.white;
    }
    return Colors.white.withOpacity(0.9);
  }

  Widget _buildQualityIndicator() {
    return Row(
      children: List.generate(5, (index) {
        return Container(
          width: 3,
          height: 8,
          margin: const EdgeInsets.symmetric(horizontal: 1),
          decoration: BoxDecoration(
            color: index < quality
                ? _getQualityColor()
                : Colors.white.withOpacity(0.3),
            borderRadius: BorderRadius.circular(1),
          ),
        );
      }),
    );
  }

  Color _getQualityColor() {
    if (connectivity == ConnectivityResult.none) {
      return Colors.white.withOpacity(0.7);
    }
    if (quality <= 2) {
      return Colors.white;
    }
    if (quality <= 3) {
      return Colors.yellow;
    }
    return Colors.green;
  }
}
