# Supabase — migrations

## Estrutura

Migrations numeradas por timestamp em `migrations/`. Aplicar em ordem lexicográfica (001 → 008).

## Aplicar localmente ou no projeto remoto

```bash
supabase login
supabase link --project-ref <PROJECT_REF>
supabase db push
```

## Reset local (desenvolvimento)

```bash
supabase db reset
```

Isso recria o banco local e reaplica todas as migrations + `seed.sql`.

## Seed mínima

`seed.sql` popula clínica, **auth.users** (→ profiles via trigger), paciente, questionário demo e resposta concluída. Senha local: `TesteMVP2025!`. Ver `docs/database-model.md` (Auth/RLS).

## Notas

- RLS está **habilitado** sem policies — revisar antes de conectar clientes públicos.
- Validações cross-table estão na migration `20250525120008_cross_table_integrity_triggers.sql`.
