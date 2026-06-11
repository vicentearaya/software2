import 'package:cleanpool_app/core/utils/responsive_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('detecta mobile, tablet y desktop', (tester) async {
    Future<void> pumpWithSize(Size size) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(size: size),
            child: Builder(
              builder: (context) {
                return SizedBox(
                  key: ValueKey('${size.width}x${size.height}'),
                  width: size.width,
                  height: size.height,
                );
              },
            ),
          ),
        ),
      );
    }

    await pumpWithSize(const Size(360, 800));
    final mobileContext = tester.element(find.byKey(const ValueKey('360.0x800.0')));
    expect(ResponsiveUtils.isMobile(mobileContext), isTrue);
    expect(ResponsiveUtils.isTablet(mobileContext), isFalse);
    expect(ResponsiveUtils.isDesktop(mobileContext), isFalse);

    await pumpWithSize(const Size(800, 600));
    final tabletContext = tester.element(find.byKey(const ValueKey('800.0x600.0')));
    expect(ResponsiveUtils.isMobile(tabletContext), isFalse);
    expect(ResponsiveUtils.isTablet(tabletContext), isTrue);
    expect(ResponsiveUtils.isDesktop(tabletContext), isFalse);

    await pumpWithSize(const Size(1280, 800));
    final desktopContext = tester.element(find.byKey(const ValueKey('1280.0x800.0')));
    expect(ResponsiveUtils.isDesktop(desktopContext), isTrue);
  });
}
