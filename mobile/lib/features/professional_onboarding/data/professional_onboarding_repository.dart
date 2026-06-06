import '../../../core/errors/error_mapper.dart';
import '../../../core/network/edge_api_client.dart';
import '../domain/create_professional_account_request.dart';

class ProfessionalOnboardingRepository {
  ProfessionalOnboardingRepository({
    EdgeApiClient? edgeApi,
  }) : _edgeApi = edgeApi ?? EdgeApiClient();

  final EdgeApiClient _edgeApi;

  Future<void> createProfessionalAccount(
    CreateProfessionalAccountRequest request,
  ) async {
    try {
      await _edgeApi.invoke(
        'create-professional-account',
        body: request.toJson(),
      );
    } catch (e) {
      throw mapToAppException(e);
    }
  }
}
