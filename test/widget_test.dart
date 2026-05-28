import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';

import 'package:mosaic_desktop_template/main.dart';

void main() {
  testWidgets('App builds without crashing', (WidgetTester tester) async {
    await tester.pumpWidget(const MosaicHubApp(home: SizedBox.shrink()));

    expect(find.byType(MosaicHubApp), findsOneWidget);
  });
}
