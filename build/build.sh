#!/usr/bin/env bash
# Merges the ADD section files into a single document and exports PDF + DOCX.
# Usage:  cd build && ./build.sh

set -euo pipefail

cd "$(dirname "$0")"
ADD_DIR="../add"
OUT="merged.md"

echo "==> Merging sections..."
cat metadata.yaml > "$OUT"
echo "" >> "$OUT"

# Sorted order gives 01..11 then appendix-a
for f in $(ls "$ADD_DIR"/*.md | sort); do
  echo "    + $(basename "$f")"
  cat "$f" >> "$OUT"
  printf '\n\n' >> "$OUT"
done

echo "==> Checking for unfilled placeholders..."
if grep -n '\[\[' "$OUT" > /dev/null 2>&1; then
  echo "    WARNING: unfilled [[ ... ]] placeholders remain:"
  grep -n '\[\[' "$OUT" | head -20
  echo ""
fi

echo "==> Checking diagram references resolve..."
MISSING=0
while read -r img; do
  [ -z "$img" ] && continue
  if [ ! -f "$ADD_DIR/$img" ]; then
    echo "    MISSING: $img"
    MISSING=$((MISSING+1))
  fi
done < <(grep -o '(\.\./diagrams/[^)]*)' "$OUT" 2>/dev/null | tr -d '()' | sort -u)

if [ "$MISSING" -eq 0 ]; then
  echo "    all referenced diagrams present"
else
  echo "    $MISSING diagram(s) missing - PDF will show broken image boxes"
fi

if ! command -v pandoc >/dev/null 2>&1; then
  echo ""
  echo "pandoc not installed - stopping after merge."
  echo "merged.md is ready. Either install pandoc:"
  echo "    macOS:   brew install pandoc basictex"
  echo "    Ubuntu:  sudo apt install pandoc texlive-xetex"
  echo "or just paste merged.md into Google Docs and export from there."
  echo "(The second option is faster if you hit any LaTeX errors. Don't lose an hour to this.)"
  exit 0
fi

# DOCX first - it needs no LaTeX, so it almost always works.
echo "==> Building DOCX..."
if pandoc "$OUT" --resource-path=..:../add:../diagrams -o UrbanRide_ADD.docx; then
  echo "    build/UrbanRide_ADD.docx"
else
  echo "    DOCX build failed"
fi

echo "==> Building PDF..."
if pandoc "$OUT" --resource-path=..:../add:../diagrams --pdf-engine=xelatex -o UrbanRide_ADD.pdf 2>/tmp/pdf_err.log; then
  echo "    build/UrbanRide_ADD.pdf"
else
  echo ""
  echo "    PDF build failed - LaTeX is probably incomplete. First error:"
  grep -v "^\[WARNING\]" /tmp/pdf_err.log | grep -v "^$" | head -4 | sed "s/^/      /"
  echo ""
  echo "    DO NOT DEBUG THIS TONIGHT. Options, fastest first:"
  echo "      1. Open UrbanRide_ADD.docx in Word/Google Docs and Save As PDF"
  echo "      2. Full LaTeX install: brew install --cask mactex   /   sudo apt install texlive-full"
  echo ""
fi

echo ""
echo "OPEN THE OUTPUT AND LOOK AT IT before submitting."
echo "Check: diagrams not pixelated, tables not broken across pages, TOC correct."
