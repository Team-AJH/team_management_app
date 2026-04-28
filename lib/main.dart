import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:firebase_core/firebase_core.dart';
import 'backend/services/firebase/firebase_options.dart';

import 'frontend/theme/theme_model.dart';
import 'frontend/theme/app_theme.dart';
import 'frontend/screens/login_page.dart';
import 'frontend/screens/register_page.dart';
import 'frontend/screens/main_layout.dart';
import 'backend/services/firebase/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'backend/repositories/group_repository.dart';
import 'backend/repositories/chat_repository.dart';
import 'backend/repositories/event_repository.dart';
import 'backend/repositories/announcement_repository.dart';
import 'backend/repositories/tracker_repository.dart';
import 'backend/repositories/transaction_repository.dart';
import 'backend/repositories/user_repository.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await AuthService.configurePersistence();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeModel()),
        Provider(create: (_) => GroupRepository()),
        Provider(create: (_) => ChatRepository()),
        Provider(create: (_) => EventRepository()),
        Provider(create: (_) => AnnouncementRepository()),
        Provider(create: (_) => TrackerRepository()),
        Provider(create: (_) => TransactionRepository()),
        Provider(create: (_) => UserRepository()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeModel>(
      builder: (context, themeModel, child) {
        return MaterialApp(
          title: 'Sports Management',
          debugShowCheckedModeBanner: false,
          themeMode: themeModel.isDarkMode ? ThemeMode.dark : ThemeMode.light,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          home: const AuthWrapper(),
          routes: {
            '/login': (context) => const LoginPage(),
            '/register': (context) => const RegisterPage(),
            '/dashboard': (context) => const MainLayout(),
          },
        );
      },
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: AuthService().userChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasData) {
          return const MainLayout();
        }
        return const LoginPage();
      },
    );
  }
}
