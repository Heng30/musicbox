import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

import 'models/util.dart';
import 'pages/home.dart';
import 'routes/routes.dart';
import 'binding/binding.dart';
import 'theme/theme.dart';
import 'theme/controller.dart';
import 'lang/translation_service.dart';

void main() async {
  initGlobalController();

  if (isDesktopPlatform()) {
    WidgetsFlutterBinding.ensureInitialized();
    await windowManager.ensureInitialized();

    WindowOptions windowOptions = WindowOptions(
      size: Size(CTheme.windowWidth, CTheme.windowHeight),
      center: true,
      fullScreen: false,
      backgroundColor: Colors.transparent,
      skipTaskbar: false,
      titleBarStyle: TitleBarStyle.hidden,
      windowButtonVisibility: false,
    );
    windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
    });
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,

      initialBinding: InitControllerBinding(),
      home: const HomePage(),

      // routes
      initialRoute: "/",
      getPages: AppPage.routes,
      unknownRoute: AppPage.nofound,
      defaultTransition: Transition.rightToLeft,

      // theme
      theme: ThemeController.light,
      darkTheme: ThemeController.dark,
      themeMode: ThemeMode.light,

      // translation
      locale: const Locale('zh', 'CN'),
      fallbackLocale: TranslationService.fallbackLocal,
      translations: TranslationService(),
    );
  }
}
