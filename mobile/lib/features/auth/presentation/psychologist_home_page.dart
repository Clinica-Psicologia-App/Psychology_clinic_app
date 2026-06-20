import 'package:flutter/material.dart';

import '../../profile/domain/profile_role.dart';
import 'role_home_shell.dart';

class PsychologistHomePage extends StatelessWidget {
  const PsychologistHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const RoleHomeShell(
      title: 'EsquemaCore',
      subtitle: 'Área do profissional',
      role: ProfileRole.psychologist,
    );
  }
}
