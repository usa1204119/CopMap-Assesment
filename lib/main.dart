import 'package:copmap_flutter/providers/auth_provider.dart' as copmap_flutter;
import 'package:copmap_flutter/screens/login_screen.dart';
import 'package:copmap_flutter/screens/main_layout.dart';
import 'package:copmap_flutter/screens/officer/officer_app_layout.dart';
import 'package:copmap_flutter/models/officer.dart';
import 'package:copmap_flutter/models/user_role.dart';
import 'package:copmap_flutter/services/database_service.dart';
import 'package:copmap_flutter/theme/app_theme.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

Future<void> _initializeFirebase() async {
  try {
    // Initialize Firebase with explicit options
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: const FirebaseOptions(
          apiKey: "AIzaSyCVOnasZiHcbmdLobh0hjUSRxDpLAafXw8",
          appId: "1:851038769976:android:15dd8a1bf03ba3601de7cd",
          messagingSenderId: "851038769976",
          projectId: "copmap-dashboard",
          storageBucket: "copmap-dashboard.firebasestorage.app",
          authDomain: "copmap-dashboard.firebaseapp.com",
        ),
      );
      print('Firebase initialized successfully');
    }
  } catch (e) {
    print('Firebase initialization warning (non-fatal): $e');
    // Continue without Firebase - the app will still work
    // Just log the error and proceed
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Wait for Firebase initialization (required for web and critical services)
  await _initializeFirebase();

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => copmap_flutter.AuthProvider(),
      child: MaterialApp(
        title: 'CopMap',
        theme: AppTheme.darkTheme,
        debugShowCheckedModeBanner: false,
        home: Consumer<copmap_flutter.AuthProvider>(
          builder: (context, authProvider, _) {
            // Show loading screen while checking auth state
            if (authProvider.user == null && authProvider.isLoading) {
              return const Scaffold(
                backgroundColor: AppTheme.background,
                body: Center(child: CircularProgressIndicator()),
              );
            }

            // Route based on authentication state
            if (!authProvider.isAuthenticated) {
              return const LoginScreen();
            }

            // Route based on user role instead of platform
            // Station Master gets web dashboard, Field Officer gets mobile app
            final userEmail = authProvider.user?.email ?? '';
            final userRole = UserRoleExtension.determineRoleFromEmail(
              userEmail,
            );
            final isStationMaster = userRole == UserRole.stationMaster;

            if (isStationMaster) {
              // Station Master gets web dashboard
              return const MainLayout();
            } else {
              // Field Officer gets mobile app
              return _OfficerAppLoader(userId: authProvider.user!.uid);
            }
          },
        ),
      ),
    );
  }
}

/// Officer App Loader - Fetches officer data and routes to OfficerAppLayout
class _OfficerAppLoader extends StatefulWidget {
  final String userId;

  const _OfficerAppLoader({required this.userId});

  @override
  State<_OfficerAppLoader> createState() => _OfficerAppLoaderState();
}

class _OfficerAppLoaderState extends State<_OfficerAppLoader> {
  late Future<Officer?> _officerFuture;

  @override
  void initState() {
    super.initState();
    _officerFuture = _loadOfficer();
  }

  Future<Officer?> _loadOfficer() async {
    try {
      // Query officers collection by user ID from Firebase Auth
      final db = DatabaseService();
      final officer = await db.getOfficer(widget.userId);

      if (officer != null) {
        return officer;
      }

      // If officer not found in Firestore, create a basic officer record
      // This handles cases where user exists in Auth but not in Firestore
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await db.createOfficerFromUser(
          user,
          badgeNumber:
              'Badge #${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}',
        );
        // Try again after creating
        return await db.getOfficer(widget.userId);
      }

      return null;
    } catch (e) {
      print('Error loading officer: $e');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Officer?>(
      future: _officerFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: AppTheme.background,
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text(
                    'Loading Officer Data...',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
          );
        }

        if (snapshot.hasError || snapshot.data == null) {
          return Scaffold(
            backgroundColor: AppTheme.background,
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error,
                    color: AppTheme.statusOffline,
                    size: 40,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Error Loading Officer Data',
                    style: TextStyle(color: Colors.white),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    snapshot.error?.toString() ?? 'Unknown error',
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        final officer = snapshot.data!;
        return OfficerAppLayout(officerId: widget.userId, officer: officer);
      },
    );
  }
}
