import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/services.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'core/theme.dart';
import 'models/app_state.dart';
import 'screens/home_screen.dart';
import 'screens/tracking/tracking_result_screen.dart';
import 'services/deep_link_handler.dart';
import 'dart:io';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
final DeepLinkHandler deepLinkHandler = DeepLinkHandler();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");

  await FlutterNaverMap().init(
    clientId: dotenv.get('NAVER_MAP_CLIENT_ID'),
    onAuthFailed: (ex) {
      debugPrint('Naver Map Auth Failed: $ex');
    },
  );

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.green,
      statusBarIconBrightness: Brightness.light,
    ),
  );
  HttpOverrides.global = MyHttpOverrides();
  runApp(
    ChangeNotifierProvider(create: (_) => AppState(), child: const MyApp()),
  );
}

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback = (X509Certificate cert, String host, int port) => true;
  }
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _isCheckingTrackingStatus = true;

  @override
  void initState() {
    super.initState();

    // MaterialApp 빌드 후 딥링크 처리
    WidgetsBinding.instance.addPostFrameCallback((_) {
      deepLinkHandler.startListening();
    });

    _checkTrackingStatus();
  }

  Future<void> _checkTrackingStatus() async {
    final appState = Provider.of<AppState>(context, listen: false);
    final hasActiveTracking = await appState.checkTrackingStatus();

    if (mounted) {
      setState(() {
        _isCheckingTrackingStatus = false;
      });
    }
  }

  @override
  void dispose() {
    deepLinkHandler.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isCheckingTrackingStatus) {
      return const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    return MaterialApp(
      title: 'Ollana',
      theme: appTheme,
      navigatorKey: navigatorKey,
      home: const HomeScreen(),
      routes: {
        '/tracking-result': (context) => TrackingResultScreen(
              resultData: {
                'badge': '',
                'averageHeartRate': 0,
                'maxHeartRate': 0,
                'timeDiff': 0,
              },
              selectedMode: 'GENERAL',
            ),
      },
    );
  }
}
