import 'package:flutter/material.dart';

import '../../../../shared/widgets/desktop_admin/desktop_admin_kit.dart';
import '../../../profile/presentation/widgets/user_avatar.dart';
import '../../../user_management/domain/clinic_user.dart';

/// Distribuição de pacientes em desktop: tabela só de leitura (sem clique,
/// sem painel), com o mesmo status do celular.
class DesktopPatientOverviewView extends StatelessWidget {
  const DesktopPatientOverviewView({super.key, required this.psychologists});

  final List<ClinicUser> psychologists;

  static (String, Color?) statusOf(ClinicUser u) {
    if (!u.isActive) return ('Inativo', null);
    if (!u.canReceivePatients) return ('Bloqueado', const Color(0xFFDC2626));
    if (u.reachedPatientAssignmentLimit) {
      return ('Capacidade máxima', const Color(0xFFB45309));
    }
    return ('Disponível', const Color(0xFF059669));
  }

  @override
  Widget build(BuildContext context) {
    final t = DesktopAdminTokens.of(context);
    final m = DesktopAdminMetrics.of(MediaQuery.sizeOf(context).width);
    Widget h(String s, {double? w, bool right = false}) {
      final text = Text(s,
          maxLines: 1,
          textAlign: right ? TextAlign.right : TextAlign.left,
          style: daText(context, t,
              size: 12, weight: FontWeight.w500, color: t.tx3));
      return w == null ? Expanded(child: text) : SizedBox(width: w, child: text);
    }

    return Padding(
      padding: EdgeInsets.fromLTRB(
          m.pad, m.size == DesktopAdminSize.desktop ? 24 : 18, m.pad, 24),
      child: Container(
        decoration: BoxDecoration(
          color: t.rz,
          border: Border.all(color: t.bd2),
          borderRadius: BorderRadius.circular(12),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            Container(
              height: 38,
              padding: const EdgeInsets.only(left: 18, right: 24),
              decoration: BoxDecoration(
                color: t.side,
                border: Border(bottom: BorderSide(color: t.bd2)),
              ),
              child: Row(children: [
                h('Psicólogo'),
                h('Status', w: m.tablet ? 150 : 170),
                h('Pacientes ativos', w: m.tablet ? 120 : 150, right: true),
                h('Convites pendentes', w: m.tablet ? 150 : 170, right: true),
              ]),
            ),
            Expanded(
              child: psychologists.isEmpty
                  ? Center(
                      child: Text('Nenhum psicólogo cadastrado.',
                          style: daText(context, t, color: t.tx3)))
                  : ListView(
                      children: [
                        for (final u in psychologists)
                          Container(
                            height: m.row,
                            padding: const EdgeInsets.only(left: 18, right: 24),
                            decoration: BoxDecoration(
                                border:
                                    Border(bottom: BorderSide(color: t.bd))),
                            child: Row(children: [
                              Expanded(
                                child: Row(children: [
                                  UserAvatar.parts(
                                    fullName: u.fullName,
                                    initials: u.initials,
                                    role: u.role,
                                    avatarType: u.avatarType,
                                    photoUrl: u.photoUrl,
                                    avatarConfig: u.avatarConfig,
                                    size: 30,
                                  ),
                                  const SizedBox(width: 12),
                                  Flexible(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(u.fullName,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: daText(context, t,
                                                weight: FontWeight.w600)),
                                        if (u.crp != null && u.crp!.isNotEmpty)
                                          Text('CRP ${u.crp}',
                                              style: daText(context, t,
                                                  size: 12, color: t.tx3)),
                                      ],
                                    ),
                                  ),
                                ]),
                              ),
                              SizedBox(
                                width: m.tablet ? 150 : 170,
                                child: Align(
                                  alignment: Alignment.centerLeft,
                                  child: _status(context, u),
                                ),
                              ),
                              SizedBox(
                                width: m.tablet ? 120 : 150,
                                child: Text('${u.assignedPatientsCount}',
                                    textAlign: TextAlign.right,
                                    style: daText(context, t)),
                              ),
                              SizedBox(
                                width: m.tablet ? 150 : 170,
                                child: Text(
                                    '${u.pendingPatientInvitationsCount}',
                                    textAlign: TextAlign.right,
                                    style: daText(context, t)),
                              ),
                            ]),
                          ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _status(BuildContext context, ClinicUser u) {
    final (label, color) = statusOf(u);
    final t = DesktopAdminTokens.of(context);
    if (color == null) return DaTag(label);
    if (label == 'Disponível') return DaTag.ok(context, label);
    return DaTag(label,
        fg: color,
        bg: color.withValues(alpha: t.dark ? 0.2 : 0.12));
  }
}
