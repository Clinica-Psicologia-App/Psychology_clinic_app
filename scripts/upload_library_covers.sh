#!/usr/bin/env bash
# Sobe as capas da Biblioteca para o bucket público `library-covers`.
#
# Uso:
#   SUPABASE_URL="https://wxotrgmhevztoquqqmno.supabase.co" \
#   SERVICE_ROLE_KEY="eyJ...sua_service_role..." \
#   ./scripts/upload_library_covers.sh /caminho/para/a/pasta_de_capas
#
# A pasta deve conter arquivos nomeados pelo número da ficha: 1.jpg, 2.jpg, ...
# Reexecutar sobrescreve (x-upsert). Só sobe .jpg/.jpeg/.png/.webp.

set -euo pipefail

FOLDER="${1:-}"
: "${SUPABASE_URL:?defina SUPABASE_URL}"
: "${SERVICE_ROLE_KEY:?defina SERVICE_ROLE_KEY}"
if [[ -z "$FOLDER" || ! -d "$FOLDER" ]]; then
  echo "Pasta inválida. Uso: $0 /caminho/para/pasta" >&2
  exit 1
fi

content_type() {
  case "${1,,}" in
    *.png) echo "image/png" ;;
    *.webp) echo "image/webp" ;;
    *) echo "image/jpeg" ;;
  esac
}

count=0
for file in "$FOLDER"/*.{jpg,jpeg,png,webp}; do
  [[ -e "$file" ]] || continue
  name="$(basename "$file")"
  ct="$(content_type "$file")"
  echo "→ enviando $name ($ct)"
  curl -sS -X POST \
    "$SUPABASE_URL/storage/v1/object/library-covers/$name" \
    -H "Authorization: Bearer $SERVICE_ROLE_KEY" \
    -H "Content-Type: $ct" \
    -H "x-upsert: true" \
    --data-binary "@$file" > /dev/null
  count=$((count + 1))
done

echo "Concluído: $count arquivo(s) enviado(s) para library-covers."
