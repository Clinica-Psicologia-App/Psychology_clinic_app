import 'package:flutter/material.dart';

import '../../profile/domain/profile_role.dart';
import 'role_home_shell.dart';

class AdminHomePage extends StatelessWidget {
  const AdminHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const RoleHomeShell(
      title: 'Administração',
      subtitle: 'Painel da clínica',
      role: ProfileRole.admin,
    );
  }
}
