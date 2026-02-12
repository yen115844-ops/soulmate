import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'config/routes/app_router.dart';
import 'config/routes/route_names.dart';
import 'core/di/injection.dart';
import 'core/services/auth_service.dart';
import 'core/services/chat_socket_service.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_cubit.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/auth/presentation/bloc/auth_event.dart';
import 'features/auth/presentation/bloc/auth_state.dart' as auth_state;
import 'features/partner/data/partner_repository.dart';
import 'features/profile/presentation/bloc/profile_bloc.dart';
import 'features/profile/presentation/bloc/profile_event.dart';
import 'shared/bloc/master_data_bloc.dart';

/// The main application widget
class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> with WidgetsBindingObserver {
  late final StreamSubscription<AuthState> _authSubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _authSubscription = getIt<AuthService>().authStateStream.listen(
      _onAuthStateChanged,
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _updatePresence();
    }
  }

  /// Update lastActiveAt on backend so "online" shows on Home/Favorites.
  void _updatePresence() {
    getIt<PartnerRepository>()
        .updatePresence()
        .catchError((_) {});
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _authSubscription.cancel();
    super.dispose();
  }

  void _onAuthStateChanged(AuthState state) {
    if (state == AuthState.sessionExpired) {
      _handleAuthFailed('Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.');
    }
  }

  void _handleAuthFailed(String message) {
    // Show a snackbar and redirect to login
    final context = AppRouter.navigatorKey.currentContext;
    if (context != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 3),
        ),
      );
    }
    // Navigate to login
    AppRouter.router.go(RouteNames.login);
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<ThemeCubit>.value(value: getIt<ThemeCubit>()),
        BlocProvider<AuthBloc>.value(
          value: getIt<AuthBloc>()..add(const AuthCheckRequested()),
        ),
      ],
      child: BlocListener<AuthBloc, auth_state.AuthState>(
        listener: (context, state) {
          if (state is auth_state.AuthUnauthenticated) {
            // Reset singleton BLoCs to clear old user data in memory
            getIt<ProfileBloc>().add(const ProfileResetRequested());
            getIt<MasterDataBloc>().add(const MasterDataResetRequested());
            ChatSocketService.instance.disconnect();
            AppRouter.router.go(RouteNames.login);
          } else if (state is auth_state.AuthAuthenticated ||
              state is auth_state.AuthNeedsProfileSetup) {
            ChatSocketService.instance.connect();
            _updatePresence();
          }
        },
        child: BlocBuilder<ThemeCubit, ThemeState>(
          builder: (context, themeState) {
            return MaterialApp.router(
              title: 'Mate Social',
              debugShowCheckedModeBanner: false,

              // Theme
              theme: AppTheme.lightTheme,
              darkTheme: AppTheme.darkTheme,
              themeMode: themeState.themeMode,
              localizationsDelegates: const [
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              supportedLocales: const [
                Locale('vi', 'VN'),
                Locale('en', ''),
                Locale('ko', ''),
              ],
              localeResolutionCallback: (locale, supported) {
                if (locale != null) {
                  final match = supported.cast<Locale?>().firstWhere(
                    (s) => s?.languageCode == locale.languageCode,
                    orElse: () => null,
                  );
                  if (match != null) return match;
                }
                return const Locale('vi', 'VN');
              },
              routerConfig: AppRouter.router,

              // Builder for global configurations
              builder: (context, child) {
                // Configure flutter_animate default values
                Animate.restartOnHotReload = true;

                // Use AnnotatedRegion instead of imperative SystemChrome call
                final isDark = Theme.of(context).brightness == Brightness.dark;
                return AnnotatedRegion<SystemUiOverlayStyle>(
                  value: SystemUiOverlayStyle(
                    statusBarColor: Colors.transparent,
                    statusBarIconBrightness: isDark
                        ? Brightness.light
                        : Brightness.dark,
                    systemNavigationBarColor: Theme.of(
                      context,
                    ).scaffoldBackgroundColor,
                    systemNavigationBarIconBrightness: isDark
                        ? Brightness.light
                        : Brightness.dark,
                  ),
                  child: GestureDetector(
                    onTap: () => FocusScope.of(context).unfocus(),
                    child: MediaQuery(
                      // Set max text scale factor for accessibility
                      data: MediaQuery.of(context).copyWith(
                        textScaler: TextScaler.linear(
                          MediaQuery.of(
                            context,
                          ).textScaler.scale(1.0).clamp(0.8, 1.2),
                        ),
                      ),
                      child: child ?? const SizedBox.shrink(),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
