#!/usr/bin/env bash
if [[ $# -lt 2 ]]; then
  echo "Uso: $0 <dominio> <extensao|all>"
  echo "Exemplos:"
  echo "  $0 exemplo.com pdf"
  echo "  $0 exemplo.com all"
  exit 1
fi

DOMINIO="$1"
EXTENSAO="$2"

EXT_LIST_DEFAULT=(pdf doc docx xls xlsx ppt pptx)

ARQUIVO_FINAL="resultados_${DOMINIO}_${EXTENSAO}.txt"

TEMP_DIR="$(mktemp -d /tmp/multi_search_dorks.XXXX)"


function busca_no_google() {
  local domain="$1"
  local ext="$2"

  echo "[+] Buscando por .$ext no domínio $domain ..."

  local raw_file="${TEMP_DIR}/google_${ext}.tmp"


  lynx -connect_timeout=10 -read_timeout=10 -dump \
    "https://www.google.com/search?q=site:${domain}+filetype:${ext}&num=50" \
    > "${raw_file}" 2>/dev/null


  grep -Eo 'https?://[^ ]+' "${raw_file}"                \
    | sed 's|https://www.google.com/url?q=||g'           \
    | sed 's|&.*||g'                                     \
    | grep -i "${domain}"                                \
    | grep -Ei "\.${ext}(\b|[^a-zA-Z0-9])"               \
    >> "${TEMP_DIR}/all_found_links.txt"
}


if [[ "${EXTENSAO,,}" == "all" ]]; then
  EXT_LIST=("${EXT_LIST_DEFAULT[@]}")
else
  EXT_LIST=("$EXTENSAO")
fi


for e in "${EXT_LIST[@]}"; do
  busca_no_google "${DOMINIO}" "${e}"
done


sort -u "${TEMP_DIR}/all_found_links.txt" -o "${ARQUIVO_FINAL}"
TOTAL_RESULTADOS=$(wc -l < "${ARQUIVO_FINAL}" 2>/dev/null || echo 0)

if [[ "${TOTAL_RESULTADOS}" -gt 0 ]]; then
  echo "[+] Total de ${TOTAL_RESULTADOS} URLs encontradas para '${DOMINIO}'."
  echo "[+] Resultados salvos em '${ARQUIVO_FINAL}'."
else
  echo "[!] Nenhum resultado encontrado para '${DOMINIO}' com as extensões pesquisadas."
  rm -f "${ARQUIVO_FINAL}" 2>/dev/null
fi


rm -rf "${TEMP_DIR}"
echo "[+] Execução concluída."
exit 0
