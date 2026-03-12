/// flutter drive 用インテグレーションテストドライバー.
///
/// 使用例: flutter drive --driver=test_driver/integration_test.dart --target=integration_test/app_test.dart -d chrome
library;

import 'package:integration_test/integration_test_driver.dart';

Future<void> main() => integrationDriver();
