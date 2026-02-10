import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/di/injection.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/auth/presentation/bloc/auth_state.dart' as auth_state;
import '../../features/auth/presentation/pages/change_password_page.dart';
import '../../features/auth/presentation/pages/forgot_password_page.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/otp_verification_page.dart';
import '../../features/auth/presentation/pages/register_page.dart';
import '../../features/auth/presentation/pages/reset_password_page.dart';
import '../../features/booking/presentation/pages/booking_confirmation_page.dart';
import '../../features/booking/presentation/pages/booking_detail_page.dart';
import '../../features/booking/presentation/pages/booking_payment_page.dart';
import '../../features/booking/presentation/pages/bookings_page.dart';
import '../../features/booking/presentation/pages/create_booking_page.dart';
import '../../features/chat/presentation/pages/chat_list_page.dart';
import '../../features/chat/presentation/pages/chat_room_page.dart';
import '../../features/chat/presentation/pages/chat_with_user_page.dart';
import '../../features/favorites/presentation/pages/favorites_page.dart';
import '../../features/home/presentation/pages/swipeable_home_page.dart';
import '../../features/notification/presentation/pages/notifications_page.dart';
import '../../features/onboarding/presentation/pages/onboarding_page.dart';
import '../../features/partner/presentation/pages/availability_slots_page.dart';
import '../../features/partner/presentation/pages/bank_account_settings_page.dart';
import '../../features/partner/presentation/pages/become_partner_page.dart';
import '../../features/partner/presentation/pages/partner_bookings_page.dart';
import '../../features/partner/presentation/pages/partner_dashboard_page.dart';
import '../../features/partner/presentation/pages/partner_detail_page.dart';
import '../../features/partner/presentation/pages/partner_earnings_page.dart';
import '../../features/partner/presentation/pages/partner_profile_page.dart';
import '../../features/partner/presentation/pages/partner_reviews_page.dart';
import '../../features/partner/presentation/pages/partner_shell_page.dart';
import '../../features/partner/presentation/pages/photo_manager_page.dart';
import '../../features/profile/presentation/pages/edit_profile_page.dart';
import '../../features/profile/presentation/pages/profile_page.dart';
import '../../features/rating/presentation/pages/my_reviews_page.dart';
import '../../features/rating/presentation/pages/write_review_page.dart';
import '../../features/safety/presentation/pages/emergency_contacts_page.dart';
import '../../features/safety/presentation/pages/kyc_page.dart';
import '../../features/safety/presentation/pages/sos_page.dart';
import '../../features/settings/presentation/pages/blocked_users_page.dart';
import '../../features/settings/presentation/pages/help_center_page.dart';
import '../../features/settings/presentation/pages/privacy_policy_page.dart';
import '../../features/settings/presentation/pages/settings_page.dart';
import '../../features/settings/presentation/pages/terms_of_service_page.dart';
// Feature Pages
import '../../features/splash/presentation/pages/splash_page.dart';
import '../../features/wallet/presentation/pages/transactions_page.dart';
import '../../features/wallet/presentation/pages/wallet_page.dart';
import '../../features/wallet/presentation/pages/wallet_topup_page.dart';
import '../../features/wallet/presentation/pages/wallet_withdraw_page.dart';
import 'route_names.dart';

/// App Router Configuration using go_router
class AppRouter {
  AppRouter._();

  static final _rootNavigatorKey = GlobalKey<NavigatorState>();
  
  /// Expose navigator key for global access
  static GlobalKey<NavigatorState> get navigatorKey => _rootNavigatorKey;

  static GoRouter get router => _router;

  static final GoRouter _router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: RouteNames.splash,
    debugLogDiagnostics: true,
    routes: [
      // Splash Screen
      GoRoute(
        path: RouteNames.splash,
        name: 'splash',
        builder: (context, state) => const SplashPage(),
      ),

      // Onboarding
      GoRoute(
        path: RouteNames.onboarding,
        name: 'onboarding',
        builder: (context, state) => const OnboardingPage(),
      ),

      // Auth Routes
      GoRoute(
        path: RouteNames.login,
        name: 'login',
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: RouteNames.register,
        name: 'register',
        builder: (context, state) => const RegisterPage(),
      ),
      GoRoute(
        path: RouteNames.otpVerification,
        name: 'otp-verification',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return OtpVerificationPage(
            phone: extra?['phone'] ?? '',
            email: extra?['email'] as String?,
            isRegister: extra?['isRegister'] ?? false,
          );
        },
      ),
      GoRoute(
        path: RouteNames.forgotPassword,
        name: 'forgot-password',
        builder: (context, state) => const ForgotPasswordPage(),
      ),
      GoRoute(
        path: RouteNames.resetPassword,
        name: 'reset-password',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          final email = extra?['email'] as String? ?? state.uri.queryParameters['email'] ?? '';
          return ResetPasswordPage(email: email);
        },
      ),

      // Main Home - Swipeable (Bookings - Home - Settings)
      GoRoute(
        path: RouteNames.home,
        name: 'home',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          final initialPage = extra?['initialPage'] as int? ?? 1;
          return SwipeableHomePage(initialPage: initialPage);
        },
      ),

      // Bookings Page
      GoRoute(
        path: RouteNames.bookings,
        name: 'bookings',
        builder: (context, state) => const BookingsPage(),
      ),

      // Chat List Page
      GoRoute(
        path: RouteNames.chat,
        name: 'chat',
        builder: (context, state) => const ChatListPage(),
      ),

      // Profile Page
      GoRoute(
        path: RouteNames.profile,
        name: 'profile',
        builder: (context, state) => const ProfilePage(),
      ),

      // Partner Mode Shell Route với Bottom Navigation cố định
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return PartnerShellPage(navigationShell: navigationShell);
        },
        branches: [
          // Branch 0: Dashboard
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RouteNames.partnerDashboard,
                name: 'partner-dashboard',
                builder: (context, state) => const PartnerDashboardPage(),
              ),
            ],
          ),
          // Branch 1: Bookings
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RouteNames.partnerBookings,
                name: 'partner-bookings',
                builder: (context, state) => const PartnerBookingsPage(),
              ),
            ],
          ),
          // Branch 2: Earnings
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RouteNames.partnerEarnings,
                name: 'partner-earnings',
                builder: (context, state) => const PartnerEarningsPage(),
              ),
            ],
          ),
          // Branch 3: Profile
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RouteNames.partnerProfile,
                name: 'partner-profile',
                builder: (context, state) => const PartnerProfilePage(),
              ),
            ],
          ),
        ],
      ),

      // Partner Schedule Settings (for partners)
      GoRoute(
        path: RouteNames.partnerAvailabilitySettings,
        name: 'partner-schedule-settings',
        builder: (context, state) => const AvailabilitySlotsPage(),
      ),

      // Partner Bank Account Settings
      GoRoute(
        path: RouteNames.partnerBankAccount,
        name: 'partner-bank-account',
        builder: (context, state) => const BankAccountSettingsPage(),
      ),

      // Partner Photo Manager
      GoRoute(
        path: RouteNames.partnerPhotoManager,
        name: 'partner-photo-manager',
        builder: (context, state) {
          final photos = state.extra as List<String>? ?? [];
          return PhotoManagerPage(initialPhotos: photos);
        },
      ),

      // Partner Detail (must be after specific /partner/* routes)
      GoRoute(
        path: RouteNames.partnerDetail,
        name: 'partner-detail',
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          return PartnerDetailPage(partnerId: id);
        },
      ),

      // Partner Reviews
      GoRoute(
        path: RouteNames.partnerReviews,
        name: 'partner-reviews',
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          return PartnerReviewsPage(partnerId: id);
        },
      ),

      // Create Booking
      GoRoute(
        path: RouteNames.createBooking,
        name: 'create-booking',
        builder: (context, state) {
          final partnerId = state.uri.queryParameters['partnerId'] ?? '';
          return CreateBookingPage(partnerId: partnerId);
        },
      ),

      // Notifications
      GoRoute(
        path: RouteNames.notifications,
        name: 'notifications',
        builder: (context, state) => const NotificationsPage(),
      ),

      // Wallet Routes
      GoRoute(
        path: RouteNames.wallet,
        name: 'wallet',
        builder: (context, state) => const WalletPage(),
      ),
      GoRoute(
        path: RouteNames.walletTopUp,
        name: 'wallet-topup',
        builder: (context, state) => const WalletTopUpPage(),
      ),
      GoRoute(
        path: RouteNames.walletWithdraw,
        name: 'wallet-withdraw',
        builder: (context, state) => const WalletWithdrawPage(),
      ),
      GoRoute(
        path: RouteNames.transactions,
        name: 'transactions',
        builder: (context, state) => const TransactionsPage(),
      ),

      // Profile Routes
      GoRoute(
        path: RouteNames.editProfile,
        name: 'edit-profile',
        builder: (context, state) => const EditProfilePage(),
      ),
      GoRoute(
        path: RouteNames.settings,
        name: 'settings',
        builder: (context, state) => const SettingsPage(),
      ),
      GoRoute(
        path: RouteNames.blockedUsers,
        name: 'blocked-users',
        builder: (context, state) => const BlockedUsersPage(),
      ),
      GoRoute(
        path: RouteNames.favorites,
        name: 'favorites',
        builder: (context, state) => const FavoritesPage(),
      ),
      GoRoute(
        path: RouteNames.myReviews,
        name: 'my-reviews',
        builder: (context, state) => const MyReviewsPage(),
      ),
      GoRoute(
        path: RouteNames.emergencyContacts,
        name: 'emergency-contacts',
        builder: (context, state) => const EmergencyContactsPage(),
      ),

      // KYC Page
      GoRoute(
        path: RouteNames.kyc,
        name: 'kyc',
        builder: (context, state) => const KycPage(),
      ),

      // SOS Page
      GoRoute(
        path: RouteNames.sos,
        name: 'sos',
        builder: (context, state) => const SosPage(),
      ),

      // Change Password
      GoRoute(
        path: RouteNames.changePassword,
        name: 'change-password',
        builder: (context, state) => const ChangePasswordPage(),
      ),

      // Help Center
      GoRoute(
        path: RouteNames.helpCenter,
        name: 'help-center',
        builder: (context, state) => const HelpCenterPage(),
      ),

      // Terms of Service
      GoRoute(
        path: RouteNames.termsOfService,
        name: 'terms-of-service',
        builder: (context, state) => const TermsOfServicePage(),
      ),

      // Privacy Policy
      GoRoute(
        path: RouteNames.privacyPolicy,
        name: 'privacy-policy',
        builder: (context, state) => const PrivacyPolicyPage(),
      ),

      // Booking Confirmation (after create) - PHẢI đặt trước /booking/:id
      // để tránh "confirmation" bị match thành :id
      GoRoute(
        path: RouteNames.bookingConfirmation,
        name: 'booking-confirmation',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return BookingConfirmationPage(
            bookingId: extra?['bookingId'] as String?,
            bookingCode: extra?['bookingCode'] as String?,
          );
        },
      ),
      // Booking Detail
      GoRoute(
        path: RouteNames.bookingDetail,
        name: 'booking-detail',
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          return BookingDetailPage(bookingId: id);
        },
      ),
      // Booking Payment
      GoRoute(
        path: RouteNames.bookingPayment,
        name: 'booking-payment',
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          return BookingPaymentPage(bookingId: id);
        },
      ),

      // Write Review
      GoRoute(
        path: RouteNames.writeReview,
        name: 'write-review',
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          return WriteReviewPage(bookingId: id);
        },
      ),

      // Chat với User (tạo/mở conversation)
      GoRoute(
        path: RouteNames.chatWithUser,
        name: 'chat-with-user',
        builder: (context, state) {
          final userId = state.pathParameters['userId'] ?? '';
          final extra = state.extra as Map<String, dynamic>?;
          return ChatWithUserPage(
            userId: userId,
            initialMessage: extra?['initialMessage'],
          );
        },
      ),

      // Chat New (virtual conversation - chưa có conversation)
      // PHẢI đặt trước /chat/:id vì /chat/new sẽ match :id="new" nếu route sau được check trước
      GoRoute(
        path: RouteNames.chatNew,
        name: 'chat-new',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return ChatRoomPage(
            participantId: extra?['participantId'],
            participantName: extra?['participantName'],
            participantAvatar: extra?['participantAvatar'],
          );
        },
      ),

      // Chat Room (với conversationId đã có)
      GoRoute(
        path: RouteNames.chatRoom,
        name: 'chat-room',
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          return ChatRoomPage(conversationId: id);
        },
      ),

      // Become Partner
      GoRoute(
        path: RouteNames.becomePartner,
        name: 'become-partner',
        builder: (context, state) => const BecomePartnerPage(),
      ),
    ],

    // Error Page (404) - redirect by auth
    errorBuilder: (context, state) {
      final authBloc = getIt<AuthBloc>();
      final authState = authBloc.state;
      final isLoggedIn = authState is auth_state.AuthAuthenticated ||
          authState is auth_state.AuthNeedsProfileSetup ||
          authState is auth_state.AuthPendingVerification;
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                'Không tìm thấy trang',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  state.uri.toString(),
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  if (isLoggedIn) {
                    context.go(RouteNames.home);
                  } else {
                    context.go(RouteNames.login);
                  }
                },
                child: Text(isLoggedIn ? 'Về trang chủ' : 'Về đăng nhập'),
              ),
            ],
          ),
        ),
      );
    },

    // Redirect Logic (auth guard)
    redirect: (context, state) {
      final authBloc = getIt<AuthBloc>();
      final authState = authBloc.state;
      final isLoggedIn = authState is auth_state.AuthAuthenticated ||
          authState is auth_state.AuthNeedsProfileSetup ||
          authState is auth_state.AuthPendingVerification;
      final location = state.matchedLocation;
      final isPublicRoute = location == RouteNames.splash ||
          location == RouteNames.onboarding ||
          location == RouteNames.login ||
          location == RouteNames.register ||
          location.startsWith(RouteNames.otpVerification) ||
          location == RouteNames.forgotPassword ||
          location == RouteNames.resetPassword;

      if (!isLoggedIn && !isPublicRoute) {
        return RouteNames.login;
      }
      if (isLoggedIn && (location == RouteNames.login || location == RouteNames.register)) {
        return RouteNames.home;
      }
      // Sau xác thực OTP đăng ký: đang ở /otp-verification và đã login → về home
      if (isLoggedIn && location.startsWith(RouteNames.otpVerification)) {
        return RouteNames.home;
      }
      // /main không có route riêng – dùng /home làm màn chính
      if (location == RouteNames.main) {
        return RouteNames.home;
      }
      // Không có trang Search riêng – bộ lọc ở Home: /search → /home
      if (location == RouteNames.search) {
        return RouteNames.home;
      }
      return null;
    },
  );
}
