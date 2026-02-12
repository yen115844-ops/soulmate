import 'package:get_it/get_it.dart';

import '../../features/auth/data/auth_password_repository.dart';
import '../../features/auth/data/auth_repository.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/auth/presentation/bloc/change_password_bloc.dart';
import '../../features/booking/data/booking_repository.dart';
import '../../features/booking/presentation/bloc/booking_bloc.dart';
import '../../features/chat/data/chat_repository.dart';
import '../../features/chat/presentation/bloc/chat_bloc.dart';
import '../../features/favorites/data/favorites_repository.dart';
import '../../features/favorites/presentation/bloc/favorites_bloc.dart';
import '../../features/home/data/home_repository.dart';
import '../../features/home/presentation/bloc/home_bloc.dart';
import '../../features/notification/presentation/bloc/notification_bloc.dart';
import '../../features/partner/data/partner_repository.dart';
import '../../features/partner/presentation/bloc/partner_bookings_bloc.dart';
import '../../features/partner/presentation/bloc/partner_dashboard_bloc.dart';
import '../../features/partner/presentation/bloc/partner_earnings_bloc.dart';
import '../../features/partner/presentation/bloc/partner_profile_bloc.dart';
import '../../features/partner/presentation/bloc/partner_registration_bloc.dart';
import '../../features/partner/presentation/bloc/partner_reviews_bloc.dart';
import '../../features/partner/presentation/bloc/schedule_settings_bloc.dart';
import '../../features/profile/data/profile_repository.dart';
import '../../features/profile/presentation/bloc/profile_bloc.dart';
import '../../features/rating/data/reviews_repository.dart';
import '../../features/rating/presentation/bloc/my_reviews_bloc.dart';
import '../../features/safety/data/emergency_contacts_repository.dart';
import '../../features/safety/data/kyc_repository.dart';
import '../../features/safety/presentation/bloc/emergency_contacts_bloc.dart';
import '../../features/safety/presentation/bloc/kyc_bloc.dart';
import '../../features/settings/data/settings_repository.dart';
import '../../features/settings/presentation/bloc/settings_bloc.dart';
import '../../features/wallet/data/wallet_repository.dart';
import '../../features/wallet/presentation/bloc/wallet_bloc.dart';
import '../../shared/bloc/master_data_bloc.dart';
import '../../shared/data/repositories/master_data_repository.dart';
import '../../shared/data/repositories/notification_repository.dart';
import '../network/api_client.dart';
import '../services/auth_service.dart';
import '../services/chat_socket_service.dart';
import '../services/local_storage_service.dart';
import '../services/push_notification_service.dart';
import '../theme/theme_cubit.dart';

/// Service Locator using GetIt
final GetIt getIt = GetIt.instance;

/// Setup all dependencies
Future<void> setupDependencies() async {
  // ==================== Core Services ====================

  // Local Storage Service (singleton - already initialized in main)
  getIt.registerLazySingleton<LocalStorageService>(
    () => LocalStorageService.instance,
  );

  // Auth Service (global singleton)
  getIt.registerLazySingleton<AuthService>(() => AuthService.instance);

  // Push Notification Service (singleton)
  getIt.registerLazySingleton<PushNotificationService>(
    () => PushNotificationService(),
  );

  // ==================== Network ====================

  // API Client
  getIt.registerLazySingleton<ApiClient>(() {
    final apiClient = ApiClient(storage: getIt<LocalStorageService>());

    // Setup callback for when auth fails (token expired and refresh failed)
    apiClient.onAuthFailed = () {
      getIt<AuthService>().setSessionExpired();
    };

    return apiClient;
  });

  // ==================== Repositories ====================

  // Auth Repository
  getIt.registerLazySingleton<AuthRepository>(
    () => AuthRepository(
      apiClient: getIt<ApiClient>(),
      storage: getIt<LocalStorageService>(),
    ),
  );

  // Profile Repository
  getIt.registerLazySingleton<ProfileRepository>(
    () => ProfileRepository(apiClient: getIt<ApiClient>()),
  );

  // Master Data Repository
  getIt.registerLazySingleton<MasterDataRepository>(
    () => MasterDataRepository(apiClient: getIt<ApiClient>()),
  );

  // Partner Repository
  getIt.registerLazySingleton<PartnerRepository>(
    () => PartnerRepository(apiClient: getIt<ApiClient>()),
  );

  // Notification Repository
  getIt.registerLazySingleton<NotificationRepository>(
    () => NotificationRepository(apiClient: getIt<ApiClient>()),
  );

  // Wallet Repository
  getIt.registerLazySingleton<WalletRepository>(
    () => WalletRepository(apiClient: getIt<ApiClient>()),
  );

  // Settings Repository
  getIt.registerLazySingleton<SettingsRepository>(
    () => SettingsRepository(apiClient: getIt<ApiClient>()),
  );

  // Favorites Repository
  getIt.registerLazySingleton<FavoritesRepository>(
    () => FavoritesRepository(getIt<ApiClient>()),
  );

  // Reviews Repository
  getIt.registerLazySingleton<ReviewsRepository>(
    () => ReviewsRepository(getIt<ApiClient>()),
  );

  // KYC Repository
  getIt.registerLazySingleton<KycRepository>(
    () => KycRepository(getIt<ApiClient>()),
  );

  // Emergency Contacts Repository
  getIt.registerLazySingleton<EmergencyContactsRepository>(
    () => EmergencyContactsRepository(getIt<ApiClient>()),
  );

  // Auth Password Repository
  getIt.registerLazySingleton<AuthPasswordRepository>(
    () => AuthPasswordRepository(getIt<ApiClient>()),
  );

  // Home Repository
  getIt.registerLazySingleton<HomeRepository>(
    () => HomeRepository(apiClient: getIt<ApiClient>()),
  );

  // Chat Repository
  getIt.registerLazySingleton<ChatRepository>(
    () => ChatRepository(apiClient: getIt<ApiClient>()),
  );

  // Booking Repository
  getIt.registerLazySingleton<BookingRepository>(
    () => BookingRepository(apiClient: getIt<ApiClient>()),
  );

  // ==================== BLoCs ====================

  // Auth BLoC - Lazy singleton to share auth state globally
  getIt.registerLazySingleton<AuthBloc>(
    () => AuthBloc(
      authRepository: getIt<AuthRepository>(),
    ),
  );

  // Profile BLoC - Singleton to share profile state across pages
  getIt.registerLazySingleton<ProfileBloc>(
    () => ProfileBloc(profileRepository: getIt<ProfileRepository>()),
  );

  // Master Data BLoC - Singleton to cache provinces/interests/talents and avoid refetch on every edit-profile open
  getIt.registerLazySingleton<MasterDataBloc>(
    () => MasterDataBloc(repository: getIt<MasterDataRepository>()),
  );

  // Partner Registration BLoC
  getIt.registerFactory<PartnerRegistrationBloc>(
    () => PartnerRegistrationBloc(repository: getIt<PartnerRepository>()),
  );

  // Partner Dashboard BLoC
  getIt.registerFactory<PartnerDashboardBloc>(
    () => PartnerDashboardBloc(
      partnerRepository: getIt<PartnerRepository>(),
      notificationRepository: getIt<NotificationRepository>(),
    ),
  );

  // Partner Profile BLoC
  getIt.registerFactory<PartnerProfileBloc>(
    () => PartnerProfileBloc(partnerRepository: getIt<PartnerRepository>()),
  );

  // Partner Bookings BLoC
  getIt.registerFactory<PartnerBookingsBloc>(
    () => PartnerBookingsBloc(partnerRepository: getIt<PartnerRepository>()),
  );

  // Partner Reviews BLoC
  getIt.registerFactory<PartnerReviewsBloc>(
    () => PartnerReviewsBloc(partnerRepository: getIt<PartnerRepository>()),
  );

  // Partner Earnings BLoC
  getIt.registerFactory<PartnerEarningsBloc>(
    () => PartnerEarningsBloc(partnerRepository: getIt<PartnerRepository>()),
  );

  // Schedule Settings BLoC
  getIt.registerFactory<ScheduleSettingsBloc>(
    () => ScheduleSettingsBloc(partnerRepository: getIt<PartnerRepository>()),
  );

  // Notification BLoC
  getIt.registerFactory<NotificationBloc>(
    () => NotificationBloc(repository: getIt<NotificationRepository>()),
  );

  // Wallet BLoC
  getIt.registerFactory<WalletBloc>(
    () => WalletBloc(repository: getIt<WalletRepository>()),
  );

  // Settings BLoC
  getIt.registerFactory<SettingsBloc>(
    () => SettingsBloc(
      settingsRepository: getIt<SettingsRepository>(),
      pushNotificationService: getIt<PushNotificationService>(),
    ),
  );

  // Favorites BLoC
  getIt.registerFactory<FavoritesBloc>(
    () => FavoritesBloc(repository: getIt<FavoritesRepository>()),
  );

  // My Reviews BLoC
  getIt.registerFactory<MyReviewsBloc>(
    () => MyReviewsBloc(getIt<ReviewsRepository>()),
  );

  // KYC BLoC
  getIt.registerFactory<KycBloc>(() => KycBloc(getIt<KycRepository>()));

  // Emergency Contacts BLoC
  getIt.registerFactory<EmergencyContactsBloc>(
    () => EmergencyContactsBloc(getIt<EmergencyContactsRepository>()),
  );

  // Change Password BLoC
  getIt.registerFactory<ChangePasswordBloc>(
    () => ChangePasswordBloc(getIt<AuthPasswordRepository>()),
  );

  // Home BLoC
  getIt.registerFactory<HomeBloc>(
    () => HomeBloc(
      repository: getIt<HomeRepository>(),
      favoritesRepository: getIt<FavoritesRepository>(),
    ),
  );

  // Chat BLoC
  getIt.registerFactory<ChatBloc>(
    () => ChatBloc(
      repository: getIt<ChatRepository>(),
      socketService: ChatSocketService.instance,
    ),
  );

  // Booking BLoC
  getIt.registerFactory<BookingBloc>(
    () => BookingBloc(bookingRepository: getIt<BookingRepository>()),
  );

  // Theme Cubit (singleton - persists across app)
  getIt.registerLazySingleton<ThemeCubit>(
    () => ThemeCubit(storageService: getIt<LocalStorageService>()),
  );
}

/// Reset all dependencies (useful for testing)
Future<void> resetDependencies() async {
  await getIt.reset();
}
