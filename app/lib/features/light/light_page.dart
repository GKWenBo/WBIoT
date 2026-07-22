import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'light_providers.dart';
import 'light_state.dart';

class LightPage extends ConsumerWidget {
  const LightPage({super.key, this.deviceId = 'light-001'});
  final String deviceId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(lightStateProvider(deviceId));

    return Scaffold(
      appBar: AppBar(title: Text('灯 · $deviceId')),
      body: Center(
        child: async.when(
          loading: () => const Text('等待设备上报…'),
          error: (e, _) => Text('解析出错：$e'),
          data: (LightState s) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.lightbulb,
                size: 96,
                color: s.on ? Colors.amber : Colors.grey,
              ),
              const SizedBox(height: 16),
              Text('开关：${s.on ? "开" : "关"}',
                  style: Theme.of(context).textTheme.titleLarge),
              Text('亮度：${s.brightness}%',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Text(
                '更新时间：${s.updatedAt.toIso8601String().substring(11, 19)}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
