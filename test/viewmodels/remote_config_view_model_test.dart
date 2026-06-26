import 'package:flutter_test/flutter_test.dart';
import 'package:openalex/services/firebase/remote_config_service.dart';
import 'package:openalex/viewmodels/remote_config_view_model.dart';

void main() {
  group('RemoteConfigService', () {
    test('NoOpRemoteConfigService returns default values', () {
      const service = NoOpRemoteConfigService(maxJournals: 12, maxKeywords: 8);
      expect(service.maxJournalsDisplayed, 12);
      expect(service.maxKeywordsDisplayed, 8);
    });
  });

  group('RemoteConfigViewModel', () {
    test('initializes and exposes values from service', () async {
      const service = NoOpRemoteConfigService(maxJournals: 15, maxKeywords: 7);
      final viewModel = RemoteConfigViewModel(service);

      await viewModel.initialize();

      expect(viewModel.maxJournalsDisplayed, 15);
      expect(viewModel.maxKeywordsDisplayed, 7);
      expect(viewModel.isFetching, isFalse);
    });

    test('fetchAndActivate updates isFetching state', () async {
      const service = NoOpRemoteConfigService();
      final viewModel = RemoteConfigViewModel(service);

      final fetchFuture = viewModel.fetchAndActivate();
      expect(viewModel.isFetching, isTrue);

      await fetchFuture;
      expect(viewModel.isFetching, isFalse);
    });
  });
}
