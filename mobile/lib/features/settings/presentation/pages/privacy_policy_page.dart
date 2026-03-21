import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../shared/widgets/buttons/app_back_button.dart';
import '../../data/terms_repository.dart';
import '../bloc/terms_bloc.dart';
import '../bloc/terms_event.dart';
import '../bloc/terms_state.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => TermsBloc(repository: getIt<TermsRepository>())
        ..add(const LoadPrivacyPolicy()),
      child: Scaffold(
        appBar: AppBar(
          leading: const AppBackButton(),
          title: const Text('Chính sách bảo mật'),
        ),
        body: BlocBuilder<TermsBloc, TermsState>(
          builder: (context, state) {
            if (state is TermsLoading || state is TermsInitial) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state is TermsError) {
              return Center(
                child: Padding(
                  padding: ResponsiveLayout.pagePadding(context),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 48,
                        color: context.appColors.textSecondary,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        state.message,
                        style: AppTypography.bodyMedium.copyWith(
                          color: context.appColors.textSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      TextButton(
                        onPressed: () {
                          context
                              .read<TermsBloc>()
                              .add(const LoadPrivacyPolicy());
                        },
                        child: const Text('Thử lại'),
                      ),
                    ],
                  ),
                ),
              );
            }

            if (state is TermsLoaded) {
              return Markdown(
                data: state.content,
                padding: EdgeInsets.symmetric(
                  horizontal: ResponsiveLayout.horizontalPadding(context),
                  vertical: 16,
                ),
                styleSheet: MarkdownStyleSheet(
                  h1: AppTypography.headlineSmall,
                  h2: AppTypography.titleLarge.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  h3: AppTypography.titleMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  p: AppTypography.bodyMedium.copyWith(
                    color: context.appColors.textSecondary,
                    height: 1.6,
                  ),
                  listBullet: AppTypography.bodyMedium.copyWith(
                    color: context.appColors.textSecondary,
                    height: 1.6,
                  ),
                ),
              );
            }

            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }
}
