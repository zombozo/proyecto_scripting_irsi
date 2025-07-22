#!/bin/bash

# Ruta base de facturas y plantilla
FACTURAS_DIR="./facturas"
PLANTILLA="./plantilla_factura_IRSI.tex"
REPORTE_CSV="./reporte_facturas/reporte_facturas.csv"

start(){
    mkdir -p "$FACTURAS_DIR"
    mkdir -p "$(dirname "$REPORTE_CSV")"

    local path
    path=$(python3 generador_compra.py)
    if [ -z "$path" ] || [ ! -f "$path" ]; then
        echo "Error: El script python no devolvió una ruta valida o el archivo no existe"
        exit 1
    fi

    echo "Archivo CSV a leer: $path"
    leer_archivo "$path"
}

leer_archivo(){
    local path="$1"
    tail -n +2 "$path" | while IFS=";" read -r id nombre_cliente ciudad direccion correo telefono ip_compra monto_total modalidad_pago estado_pago fecha_emision timestamp
    do 
        reemplazar_factura "$id" "$nombre_cliente" "$ciudad" "$direccion" "$correo" "$telefono" "$ip_compra" "$monto_total" "$modalidad_pago" "$estado_pago" "$fecha_emision" "$timestamp"
    done 
}

reemplazar_factura(){
    local id="$1"
    local nombre_cliente="$2"
    local ciudad="$3"
    local direccion="$4"
    local correo="$5"
    local telefono="$6"
    local ip_compra="$7"
    local monto_total="$8"
    local modalidad_pago="$9"
    local estado_pago="${10}"
    local fecha_emision="${11}"
    local timestamp="${12}"

    local nombre_tex="$FACTURAS_DIR/factura_$id.tex"

    # Reemplazar variables en la plantilla y crear archivo .tex
    sed -e "s/\bid_transaccion\b/$id/g" \
        -e "s/\bnombre\b/$nombre_cliente/g" \
        -e "s/\bcorreo\b/$correo/g" \
        -e "s/\btelefono\b/$telefono/g" \
        -e "s/\bdireccion\b/$direccion/g" \
        -e "s/\bciudad\b/$ciudad/g" \
        -e "s/\bcantidad\b/$monto_total/g" \
        -e "s/\bmonto\b/$monto_total/g" \
        -e "s/\bpago\b/$modalidad_pago/g" \
        -e "s/\bestado_pago\b/$estado_pago/g" \
        -e "s/\bip\b/$ip_compra/g" \
        -e "s/timestamp\b/$timestamp/g" \
        -e "s/fecha_emision\b/$fecha_emision/g" \
        "$PLANTILLA" > "$nombre_tex"

    crear_factura "$nombre_tex" "$id" "$timestamp" "$correo"
}

crear_factura(){
    local nombre_tex="$1"
    local id="$2"
    local timestamp="$3"
    local correo="$4"

    local dir=$(dirname "$nombre_tex")
    local file=$(basename "$nombre_tex")

    echo "Generando PDF para factura $id..."

    # Compilar dentro de la carpeta facturas para que quede todo ahí
    (cd "$dir" && pdflatex -interaction=nonstopmode "$file" > /dev/null 2>&1)
    local status=$?

    if [ $status -ne 0 ]; then
        echo "Error: Falló la compilación de pdflatex para factura $id"
        crear_registro "$file" "$id" "error" "$timestamp" "$correo"
        return 1
    fi

    # Limpiar auxiliares para no saturar carpeta
    rm -f "$dir"/factura_"$id".aux "$dir"/factura_"$id".log "$dir"/factura_"$id".out

    crear_registro "$file" "$id" "pendiente" "$timestamp" "$correo"
    echo "PDF generado correctamente: $dir/factura_${id}.pdf"
}

crear_registro(){
    local nombre_tex="$1"
    local id="$2"
    local estado="$3"
    local timestamp="$4"
    local correo="$5"

    local nombre_pdf="${nombre_tex%.tex}.pdf"

    # Crear CSV si no existe con encabezado
    if [ ! -f "$REPORTE_CSV" ]; then
        echo "id;correo;nombre_pdf;estado;timestamp" > "$REPORTE_CSV"
    fi

    echo "$id;$correo;$nombre_pdf;$estado;$timestamp" >> "$REPORTE_CSV"
}

start
