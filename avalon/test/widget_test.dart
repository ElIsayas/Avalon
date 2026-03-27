import 'package:avalon/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('AvalonApp se puede instanciar', () {
    const app = AvalonApp();
    expect(app, isA<AvalonApp>());
  });
}
