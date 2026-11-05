import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_client.dart';
import '../../features/sign/controllers/auth_controller.dart';
import '../../features/sign/services/auth_service.dart';
import '../services/dashboard_service.dart';

enum CountMetric { authors, categories, publishers }

final dashboardServiceProvider = Provider<DashboardService>((ref) {
  return DashboardService(
    dio: ApiClient.dio,
  );
});

Duration? _noRetry(int retryCount, Object error) => null;

final booksOverviewProvider = FutureProvider.autoDispose<BooksOverview>(
  (ref) {
    ref.watch(authControllerProvider.select((s) => s.user?.id));
    return ref.watch(dashboardServiceProvider).fetchBooksOverview();
  },
  retry: _noRetry,
);

final dashboardCountProvider =
    FutureProvider.autoDispose.family<int, CountMetric>(
  (ref, metric) {
    ref.watch(authControllerProvider.select((s) => s.user?.id));
    final service = ref.watch(dashboardServiceProvider);
    return switch (metric) {
      CountMetric.authors => service.countAuthors(),
      CountMetric.categories => service.countCategories(),
      CountMetric.publishers => service.countPublishers(),
    };
  },
  retry: _noRetry,
);

String dashboardErrorMessage(Object error) {
  if (error is DioException) return ApiAuthService.messageFor(error);
  return 'Dữ liệu trả về không đọc được. Kéo xuống để tải lại.';
}
