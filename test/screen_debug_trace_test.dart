import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:native_lens/native_lens.dart';

void main() {
  group('ScreenDebugInfo', () {
    test('toMap returns expected values', () {
      const ScreenDebugInfo info = ScreenDebugInfo(
        screenName: 'ProductDetailsScreen',
        filePath: 'lib/features/product/product_details_screen.dart',
        routeName: '/product-details',
        extra: 'userId=123',
      );

      expect(info.toMap(), <String, String?>{
        'screenName': 'ProductDetailsScreen',
        'filePath': 'lib/features/product/product_details_screen.dart',
        'routeName': '/product-details',
        'extra': 'userId=123',
      });
    });
  });

  group('NativeLensDebug', () {
    testWidgets('NativeLensScreenTrace prints once on mount', (WidgetTester tester) async {
      final List<String> printed = <String>[];
      final DebugPrintCallback originalDebugPrint = debugPrint;
      debugPrint = (String? message, {int? wrapWidth}) {
        if (message != null) {
          printed.add(message);
        }
      };

      await tester.pumpWidget(
        const Directionality(
          textDirection: TextDirection.ltr,
          child: NativeLensScreenTrace(
            screenName: 'ProductDetailsScreen',
            filePath: 'lib/features/product/product_details_screen.dart',
            routeName: '/product-details',
            child: Text('ProductDetailsView'),
          ),
        ),
      );

      await tester.pump();
      await tester.pump();

      expect(printed.length, 1);

      debugPrint = originalDebugPrint;
    });

    test('formatScreenTrace returns a readable debug trace', () {
      const ScreenDebugInfo info = ScreenDebugInfo(
        screenName: 'ProductDetailsScreen',
        filePath: 'lib/features/product/product_details_screen.dart',
        routeName: '/product-details',
        extra: 'userId=123',
      );

      final String trace = NativeLensDebug.formatScreenTrace(info);

      expect(trace, contains('[NativeLens] Screen Debug'));
      expect(trace, contains('Screen: ProductDetailsScreen'));
      expect(
        trace,
        contains('File: lib/features/product/product_details_screen.dart'),
      );
      expect(trace, contains('Route: /product-details'));
      expect(trace, contains('Extra: userId=123'));
    });

    test('formatScreenTrace omits extra when it is not provided', () {
      const ScreenDebugInfo info = ScreenDebugInfo(
        screenName: 'ProductDetailsScreen',
        filePath: 'lib/features/product/product_details_screen.dart',
        routeName: '/product-details',
      );

      final String trace = NativeLensDebug.formatScreenTrace(info);

      expect(trace, contains('[NativeLens] Screen Debug'));
      expect(trace, isNot(contains('Extra:')));
    });
  });
}
