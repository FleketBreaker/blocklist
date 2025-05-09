#!/bin/bash

# Archivos fuente
ADGUARD="adguard.txt"
HAGEZI="hagezi.txt"
OISD="oisd.txt"

# URLs oficiales de las listas
URL_ADGUARD="https://adguardteam.github.io/HostlistsRegistry/assets/filter_1.txt"
URL_HAGEZI="https://adguardteam.github.io/HostlistsRegistry/assets/filter_49.txt"
URL_OISD="https://big.oisd.nl/"

echo "🌐 Descargando listas de bloqueo..."

curl -s "$URL_ADGUARD" -o "$ADGUARD"
curl -s "$URL_HAGEZI" -o "$HAGEZI"
curl -s "$URL_OISD"   -o "$OISD"

echo "✅ Descarga completa."

# Archivos de salida limpiados
ADG_CLEAN="adg_clean.txt"
HGZ_CLEAN="hgz_clean.txt"
OISD_CLEAN="oisd_clean.txt"

echo "🧼 Normalizando listas..."

# Función para limpiar cada lista
limpiar_lista() {
  archivo="$1"
  salida="$2"
  grep -Eo '([a-zA-Z0-9.-]+\.[a-z]{2,})' "$archivo" | \
    grep -vE '^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$' | \
    grep -vE '^[0-9]+$' | \
    sort -u > "$salida"
}

# Limpiar cada archivo
limpiar_lista "$ADGUARD" "$ADG_CLEAN"
limpiar_lista "$HAGEZI" "$HGZ_CLEAN"
limpiar_lista "$OISD" "$OISD_CLEAN"

echo "✅ Listas limpiadas."

# Superposición entre pares
echo ""
echo "🔁 Superposición entre listas:"
echo ""

echo -n "🟡 AdGuard ∩ HaGeZi: "
comm -12 "$ADG_CLEAN" "$HGZ_CLEAN" | tee /tmp/adg_hgz.txt | wc -l

echo -n "🟡 AdGuard ∩ OISD: "
comm -12 "$ADG_CLEAN" "$OISD_CLEAN" | tee /tmp/adg_oisd.txt | wc -l

echo -n "🟡 HaGeZi ∩ OISD: "
comm -12 "$HGZ_CLEAN" "$OISD_CLEAN" | tee /tmp/hgz_oisd.txt | wc -l

# Intersección total entre las 3
echo -n "🧩 En las 3 listas: "
comm -12 /tmp/adg_hgz.txt "$OISD_CLEAN" | tee /tmp/tres_listas.txt | wc -l

# Mostrar algunos ejemplos concretos
echo ""
echo "📌 Ejemplos de dominios presentes en las 3 listas:"
head -n 10 /tmp/tres_listas.txt

# Limpieza opcional
rm /tmp/adg_hgz.txt /tmp/adg_oisd.txt /tmp/hgz_oisd.txt 2>/dev/null

# Conteo de registros crudos
echo ""
echo "🧮 Sumatoria total de registros de bloqueo (sin limpiar):"

adg_count=$(grep -cvE '^\s*$' "$ADGUARD")
hgz_count=$(grep -cvE '^\s*$' "$HAGEZI")
oisd_count=$(grep -cvE '^\s*$' "$OISD")
total=$((adg_count + hgz_count + oisd_count))

# Porcentajes
adg_pct=$(awk "BEGIN { printf \"%.2f\", ($adg_count/$total)*100 }")
hgz_pct=$(awk "BEGIN { printf \"%.2f\", ($hgz_count/$total)*100 }")
oisd_pct=$(awk "BEGIN { printf \"%.2f\", ($oisd_count/$total)*100 }")

echo "📄 AdGuard: $adg_count líneas  ($adg_pct%)"
echo "📄 HaGeZi:  $hgz_count líneas  ($hgz_pct%)"
echo "📄 OISD:    $oisd_count líneas  ($oisd_pct%)"
echo "🧮 Total combinado: $total líneas"

# Generar lista unificada en formato raw
echo ""
echo "🧪 Generando lista unificada conservando estructura original (raw)..."

cat "$ADGUARD" "$HAGEZI" "$OISD" | \
  grep -vE '^\s*$' | \
  sort -u > lista_unificada_raw.txt

# Agregar una línea al final para garantizar cambio en cada ejecución
echo "# Última actualización: $(date)" >> lista_unificada_raw.txt

echo "✅ lista_unificada_raw.txt generada con $(wc -l < lista_unificada_raw.txt) líneas únicas."

# Auto-subida a GitHub
echo ""
echo "🚀 Subiendo lista actualizada a GitHub..."

cd "$(dirname "$0")"

if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  git add lista_unificada_raw.txt

  if git diff --cached --quiet; then
    echo "ℹ️  No hay cambios nuevos para subir."
  else
    git commit -m "🔄 Actualización automática de lista unificada ($(date +'%Y-%m-%d %H:%M'))"
    git push
    echo "✅ Cambios subidos correctamente."
  fi
else
  echo "❌ Este script no está dentro de un repositorio Git. Abortando push."
fi
