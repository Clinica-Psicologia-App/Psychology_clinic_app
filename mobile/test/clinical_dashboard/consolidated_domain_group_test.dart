import 'package:flutter_test/flutter_test.dart';
import 'package:terapia_esquema/features/clinical_dashboard/domain/clinical_dashboard_builder.dart';
import 'package:terapia_esquema/features/clinical_dashboard/domain/consolidated_schema_row.dart';
import 'package:terapia_esquema/features/results/domain/ysq_taxonomy.dart';

ConsolidatedSchemaRow rowFor(String code, double score) {
  final t = ysqSchemaByCode(code);
  final d = ysqDomainByCode(t?.domainCode);
  return ConsolidatedSchemaRow(
    name: t?.name ?? code,
    code: code,
    score: score,
    responseId: 'r1',
    isAutoActivated: score >= 4.0,
    scaleMax: 6,
    domainCode: t?.domainCode,
    domainOrder: d?.order,
    schemaOrder: t?.order,
    unmetNeed: t?.unmetNeed,
  );
}

void main() {
  group('taxonomia YSQ', () {
    test('tem 5 domínios e 18 esquemas', () {
      expect(kYsqDomains, hasLength(5));
      expect(kYsqSchemas, hasLength(18));
    });

    test('distribuição por domínio confere com o material clínico', () {
      int count(String code) =>
          kYsqSchemas.where((s) => s.domainCode == code).length;
      expect(count(kYsqDomainDisconnection), 5);
      expect(count(kYsqDomainAutonomy), 4);
      expect(count(kYsqDomainLimits), 2);
      expect(count(kYsqDomainOtherDirected), 3);
      expect(count(kYsqDomainOvervigilance), 4);
    });

    test('códigos e ordens são únicos dentro de cada domínio', () {
      expect(kYsqSchemas.map((s) => s.code).toSet(), hasLength(18));
      for (final d in kYsqDomains) {
        final orders = kYsqSchemas
            .where((s) => s.domainCode == d.code)
            .map((s) => s.order);
        expect(orders.toSet(), hasLength(orders.length),
            reason: 'ordem duplicada no domínio ${d.code}');
      }
    });

    test('todo esquema tem domínio e necessidade preenchidos', () {
      for (final s in kYsqSchemas) {
        expect(ysqDomainByCode(s.domainCode), isNotNull, reason: s.code);
        expect(s.unmetNeed.trim(), isNotEmpty, reason: s.code);
      }
    });

    test('ordem do Domínio I é a validada pela psicóloga', () {
      final d1 = kYsqSchemas
          .where((s) => s.domainCode == kYsqDomainDisconnection)
          .toList()
        ..sort((a, b) => a.order.compareTo(b.order));
      expect(d1.map((s) => s.name).toList(), [
        'Abandono/Instabilidade',
        'Desconfiança/Abuso',
        'Privação emocional',
        'Defectividade/Vergonha',
        'Isolamento social/Alienação',
      ]);
    });
  });

  group('agrupamento por domínio', () {
    test('ordena por score decrescente dentro do domínio', () {
      // Scores propositalmente fora da ordem canônica.
      final rows = [
        rowFor('YSQ_SCHEMA_SOCIAL_ISOLATION', 5.0),
        rowFor('YSQ_SCHEMA_ABANDONMENT_INSTABILITY', 4.2),
        rowFor('YSQ_SCHEMA_EMOTIONAL_DEPRIVATION', 4.8),
      ];
      final groups = buildConsolidatedDomainGroups(rows);

      expect(groups, hasLength(1));
      expect(groups.single.schemas.map((s) => s.code).toList(), [
        'YSQ_SCHEMA_SOCIAL_ISOLATION',
        'YSQ_SCHEMA_EMOTIONAL_DEPRIVATION',
        'YSQ_SCHEMA_ABANDONMENT_INSTABILITY',
      ]);
    });

    test('empate de score mantém a ordem canônica do esquema', () {
      final rows = [
        rowFor('YSQ_SCHEMA_SOCIAL_ISOLATION', 4.5),
        rowFor('YSQ_SCHEMA_ABANDONMENT_INSTABILITY', 4.5),
        rowFor('YSQ_SCHEMA_EMOTIONAL_DEPRIVATION', 4.5),
      ];
      final groups = buildConsolidatedDomainGroups(rows);

      expect(groups.single.schemas.map((s) => s.code).toList(), [
        'YSQ_SCHEMA_ABANDONMENT_INSTABILITY',
        'YSQ_SCHEMA_EMOTIONAL_DEPRIVATION',
        'YSQ_SCHEMA_SOCIAL_ISOLATION',
      ]);
    });

    test('domínios saem em ordem canônica I..V', () {
      final groups = buildConsolidatedDomainGroups([
        rowFor('YSQ_SCHEMA_PUNITIVENESS', 4.1),
        rowFor('YSQ_SCHEMA_SUBJUGATION', 4.1),
        rowFor('YSQ_SCHEMA_ABANDONMENT_INSTABILITY', 4.1),
      ]);
      expect(groups.map((g) => g.numeral).toList(), ['I', 'IV', 'V']);
    });

    test('conta ativados sobre o total do domínio', () {
      final g = buildConsolidatedDomainGroups([
        rowFor('YSQ_SCHEMA_ABANDONMENT_INSTABILITY', 4.4),
        rowFor('YSQ_SCHEMA_MISTRUST_ABUSE', 3.2),
        rowFor('YSQ_SCHEMA_EMOTIONAL_DEPRIVATION', 4.6),
      ]).single;

      expect(g.activatedCount, 2);
      expect(g.totalCount, 3);
      expect(g.activationLabel, '2 de 3 ativados');
    });

    test('domínio sem esquemas no snapshot é omitido', () {
      final groups = buildConsolidatedDomainGroups([
        rowFor('YSQ_SCHEMA_ABANDONMENT_INSTABILITY', 4.4),
      ]);
      expect(groups, hasLength(1));
      expect(groups.single.code, kYsqDomainDisconnection);
    });

    test('modos do YAMI ficam fora dos domínios', () {
      final rows = [
        rowFor('YSQ_SCHEMA_ABANDONMENT_INSTABILITY', 4.4),
        ConsolidatedSchemaRow(
          name: 'Protetor Desligado',
          code: 'YAMI_MODE_DETACHED_PROTECTOR',
          score: 4.9,
          responseId: 'r2',
          isAutoActivated: true,
        ),
      ];

      expect(buildConsolidatedDomainGroups(rows).single.schemas, hasLength(1));
      final modes = buildConsolidatedModeGroup(rows);
      expect(modes.rows.map((r) => r.name).toList(), ['Protetor Desligado']);
      expect(modes.activatedCount, 1);
    });
  });
}
