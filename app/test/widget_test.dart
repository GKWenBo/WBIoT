// WBIoT 连接页冒烟测试：验证 App 能构建、初始状态为「断开」。
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:wbiot_app/main.dart';

void main() {
  testWidgets('连接页初始渲染：显示断开状态与连接按钮', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: WbiotApp()));
    await tester.pump();

    expect(find.text('WBIoT · 连接'), findsOneWidget);
    expect(find.text('状态：disconnected'), findsOneWidget);
    expect(find.byType(FilledButton), findsOneWidget);
  });
}
