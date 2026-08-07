import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tuneverse/core/di/cast_providers.dart';
import 'package:tuneverse/core/theme/app_theme.dart';

class CastButton extends ConsumerWidget {
  const CastButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final casting = ref.watch(isCastingProvider).valueOrNull ?? false;

    return IconButton(
      icon: Icon(
        casting ? Icons.cast_connected_rounded : Icons.cast_rounded,
        color: casting
            ? Theme.of(context).colorScheme.primary
            : AppTheme.onDarkSecondary,
      ),
      onPressed: () => _showCastSheet(context, ref, casting),
    );
  }

  void _showCastSheet(BuildContext context, WidgetRef ref, bool casting) {
    final service = ref.read(castServiceProvider);
    service.startDiscovery();

    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _CastSheet(isCasting: casting),
    ).whenComplete(() => service.stopDiscovery());
  }
}

class _CastSheet extends ConsumerWidget {
  final bool isCasting;
  const _CastSheet({required this.isCasting});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final devicesAsync = ref.watch(castDevicesProvider);
    final deviceName = ref.watch(castDeviceNameProvider).valueOrNull;
    final service = ref.read(castServiceProvider);

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isCasting ? Icons.cast_connected_rounded : Icons.cast_rounded,
                color: isCasting
                    ? Theme.of(context).colorScheme.primary
                    : AppTheme.onDark,
              ),
              const SizedBox(width: 12),
              Text(
                isCasting ? 'Casting to $deviceName' : 'Cast to device',
                style: const TextStyle(
                  color: AppTheme.onDark,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (isCasting)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.stop_circle_outlined,
                  color: Colors.redAccent),
              title: const Text('Disconnect',
                  style: TextStyle(color: Colors.redAccent)),
              onTap: () {
                service.disconnect();
                Navigator.pop(context);
              },
            ),
          if (!isCasting)
            devicesAsync.when(
              data: (devices) => devices.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Center(
                        child: Column(
                          children: [
                            SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                            SizedBox(height: 12),
                            Text(
                              'Looking for devices...',
                              style: TextStyle(
                                color: AppTheme.onDarkSecondary,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      children: devices.map((device) {
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.tv_rounded,
                              color: AppTheme.onDark),
                          title: Text(
                            device.friendlyName,
                            style: const TextStyle(color: AppTheme.onDark),
                          ),
                          onTap: () async {
                            await service.connectToDevice(device);
                            if (context.mounted) Navigator.pop(context);
                          },
                        );
                      }).toList(),
                    ),
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (_, __) => const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Text(
                    'Could not search for devices',
                    style: TextStyle(color: AppTheme.onDarkSecondary),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
