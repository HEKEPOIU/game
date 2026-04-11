#!/usr/bin/env bash
set -e


SCRIPT_DIR=$(dirname "$(realpath "$0")")
echo "Script dir: $SCRIPT_DIR"

OUTPUT="${SCRIPT_DIR}/spa_impl.c"
OUTPUT_OBJ="${SCRIPT_DIR}/spa_impl.o"

echo "Generating $OUTPUT"
echo "Output object: $OUTPUT_OBJ"

echo "// Auto-generated — review before use!" > "$OUTPUT"
echo "#define SPA_API_IMPL" >> "$OUTPUT"
echo "#define SPA_API_PROTO" >> "$OUTPUT"
echo "" >> "$OUTPUT"

find "$SCRIPT_DIR" -type f -name "*.h" | sort | while read -r header; do
    rel="${header#$SCRIPT_DIR/}"
    echo "#include <$rel>" >> "$OUTPUT"
done

echo "Generated $OUTPUT with $(grep -c '#include' $OUTPUT) headers"


clang -c $OUTPUT \
    -I${SCRIPT_DIR} \
    -fPIC -O2 -o $OUTPUT_OBJ

rm $OUTPUT

