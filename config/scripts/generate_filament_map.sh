#!/bin/bash
SOURCE="/home/mks/printer_data/config/officiall_filas_list.cfg"
API_URL="http://127.0.0.1:7125/printer/gcode/script"

if [ ! -f "$SOURCE" ]; then
    echo "Error: File $SOURCE not found"
    exit 1
fi

MAP=$(awk '{ 
    gsub(/\r/, ""); 
    gsub(/^[ \t]+|[ \t]+$/, ""); 
}
/^\[fila[0-9]+\]/ {
    idx = substr($0, 6, length($0)-6)
}
/^type[[:space:]]*=/ {
    split($0, parts, "=")
    val = parts[2]
    gsub(/^[ \t]+|[ \t]+$/, "", val)
    if (idx != "" && val != "") {
        if (result != "") { result = result "," }
        result = result idx ":" val
    }
}
END { print result }' "$SOURCE")

if [ -z "$MAP" ]; then
    echo "Error: Map is empty"
    exit 1
fi

GCODE_COMMAND="SAVE_VARIABLE VARIABLE=filament_type_map VALUE='\"$MAP\"'"

echo "Generated: $GCODE_COMMAND"

curl -G -s -o /dev/null -w "%{http_code}" \
    "$API_URL" \
    --data-urlencode "script=$GCODE_COMMAND"

echo ""
echo "Done."