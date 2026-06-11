import 'package:flutter_test/flutter_test.dart';
import 'package:random_wallpaper_generator/main.dart' as app;

void main() {
  testWidgets('App boots without throwing', (tester) async {
    app.main();
    await tester.pump();
    // First frame. No assertions on content yet — just that nothing crashed.
  });
}
