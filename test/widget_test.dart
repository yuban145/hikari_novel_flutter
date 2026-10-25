import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hikari_novel_flutter/widgets/reader_keyboard_controls.dart';

void main() {
  testWidgets('Page keys and RTL arrows navigate the reader', (tester) async {
    var page = 0;
    var toggled = false;
    await tester.pumpWidget(
      MaterialApp(
        home: ReaderKeyboardControls(
          rightToLeft: true,
          onNext: () => page++,
          onPrevious: () => page--,
          onToggleControls: () => toggled = !toggled,
          child: const Scaffold(body: Text('Reader')),
        ),
      ),
    );
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.pageDown);
    expect(page, 1);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    expect(page, 0);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    expect(page, 1);
    await tester.sendKeyEvent(LogicalKeyboardKey.pageUp);
    expect(page, 0);
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    expect(page, 1);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    expect(toggled, isTrue);
  });

  testWidgets('Editable fields do not trigger reader shortcuts', (tester) async {
    var page = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: ReaderKeyboardControls(
          onNext: () => page++,
          onPrevious: () => page--,
          onToggleControls: () {},
          child: const Scaffold(body: TextField()),
        ),
      ),
    );
    await tester.tap(find.byType(TextField));
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.pageDown);
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    expect(page, 0);
  });
}
