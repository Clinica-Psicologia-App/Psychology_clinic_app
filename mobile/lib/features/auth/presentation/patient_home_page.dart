import 'package:flutter/material.dart';

import '../../profile/domain/profile_role.dart';
import 'role_home_shell.dart';

class PatientHomePage extends StatelessWidget {
  const PatientHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const RoleHomeShell(
      title: 'Paciente',
      subtitle: 'Minha área',
      role: ProfileRole.patient,
    );
  }
}
