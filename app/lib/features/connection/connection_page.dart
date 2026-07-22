import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mqtt_client/mqtt_client.dart';

import '../../mqtt/mqtt_providers.dart';
import '../light/light_page.dart';

class ConnectionPage extends ConsumerWidget {
  const ConnectionPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(mqttConfigControllerProvider);
    final stateAsync = ref.watch(connectionStateProvider);
    final state = stateAsync.value ?? MqttConnectionState.disconnected;
    final connected = state == MqttConnectionState.connected;

    return Scaffold(
      appBar: AppBar(title: const Text('WBIoT · 连接')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              initialValue: config.host,
              decoration: const InputDecoration(
                labelText: 'Broker Host',
                helperText:
                    'iOS模拟器:127.0.0.1 / 安卓模拟器:10.0.2.2 / 真机:Mac局域网IP',
              ),
              onChanged: (v) =>
                  ref.read(mqttConfigControllerProvider.notifier).updateHost(v.trim()),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Icon(
                  Icons.circle,
                  size: 14,
                  color: connected ? Colors.green : Colors.grey,
                ),
                const SizedBox(width: 8),
                Text(
                  '状态：${state.name}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              icon: const Icon(Icons.link),
              label: const Text('连接'),
              onPressed: connected
                  ? null
                  : () async {
                      try {
                        await ref
                            .read(mqttServiceProvider)
                            .connect(ref.read(mqttConfigControllerProvider));
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('连接失败：$e')),
                          );
                        }
                      }
                    },
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              icon: const Icon(Icons.link_off),
              label: const Text('断开'),
              onPressed: connected
                  ? () => ref.read(mqttServiceProvider).disconnect()
                  : null,
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              icon: const Icon(Icons.lightbulb_outline),
              label: const Text('查看灯设备'),
              onPressed: connected
                  ? () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const LightPage()),
                      )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
