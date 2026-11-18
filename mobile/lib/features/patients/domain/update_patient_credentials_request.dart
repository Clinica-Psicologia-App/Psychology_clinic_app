/// Pedido para trocar o e-mail de acesso e/ou a senha de um paciente.
///
/// Ao menos um dos dois campos precisa vir preenchido. A senha só existe aqui
/// para ir ao servidor: este objeto nunca é impresso nem guardado.
class UpdatePatientCredentialsRequest {
  const UpdatePatientCredentialsRequest({
    required this.patientId,
    this.email,
    this.password,
  }) : assert(email != null || password != null);

  final String patientId;
  final String? email;
  final String? password;

  Map<String, dynamic> toJson() => {
        'patient_id': patientId,
        if (email != null) 'email': email,
        if (password != null) 'password': password,
      };

  /// Sem a senha: seguro para qualquer texto de diagnóstico.
  @override
  String toString() => 'UpdatePatientCredentialsRequest($patientId)';
}
