import 'package:flutter/material.dart';

class OfflineBanner extends StatelessWidget {
  final VoidCallback onDismiss;

  const OfflineBanner({super.key, required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.amber[900],
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          const Icon(Icons.wifi_off, color: Colors.white, size: 18),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'Offline — Showing cached data',
              style: TextStyle(color: Colors.white, fontSize: 13),
            ),
          ),
          GestureDetector(
            onTap: onDismiss,
            child: const Icon(Icons.close, color: Colors.white, size: 18),
          ),
        ],
      ),
    );
  }
}
