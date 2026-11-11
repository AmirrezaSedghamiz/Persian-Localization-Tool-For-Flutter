import '../lib/src/locator/string_locator.dart';

Future<void> main(List<String> args) async {
  final locator = StringLocator();
  await locator.runLocator();
}
