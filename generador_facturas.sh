#!/bin/bash

# Configuración de directorios
FACTURAS_DIR="./facturas"
LOG_DIR="./logs"
PLANTILLA="./plantilla_factura_IRSI.tex"
REPORTE_CSV="./reporte_facturas/reporte_facturas.csv"
LOG_DIARIO="$LOG_DIR/log_diario.log"

start(){
    # Crear directorios necesarios
    mkdir -p "$FACTURAS_DIR" "$LOG_DIR" "$(dirname "$REPORTE_CSV")"
    
    # Inicializar archivos de log
    touch "$LOG_DIARIO"

    # Obtener archivo CSV con datos para las facturas
    local path
    path=$(python3 generador_compra.py)
    if [ -z "$path" ] || [ ! -f "$path" ]; then
        echo "$(date '+%Y-%m-%d %H:%M:%S') - Error: Archivo CSV no encontrado" >> "$LOG_DIARIO"
        exit 1
    fi

    echo "$(date '+%Y-%m-%d %H:%M:%S') - Iniciando procesamiento de facturas" >> "$LOG_DIARIO"
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
    local log_compilacion="$LOG_DIR/compilacion_$id.log"  # Log en carpeta logs

    # Generar archivo LaTeX
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

    # Compilar a PDF
    if pdflatex -halt-on-error -output-directory "$FACTURAS_DIR" "$nombre_tex" > "$log_compilacion" 2>&1; then
        # Guardar registro con estado PENDIENTE (no exitoso)
        crear_registro "$nombre_tex" "$id" "pendiente" "$timestamp" "$correo"
        echo "$(date '+%Y-%m-%d %H:%M:%S') - EXITO - Factura $id generada para $correo" >> "$LOG_DIARIO"
    else
        local error_msg=$(grep -i "error\|!" "$log_compilacion" | head -1 | cut -d':' -f2- | sed 's/^ *//')
        crear_registro "$nombre_tex" "$id" "fallido" "$timestamp" "$correo"
        echo "$(date '+%Y-%m-%d %H:%M:%S') - ERROR - Factura $id: ${error_msg:-Error de compilación}" >> "$LOG_DIARIO"
    fi
    
    # Limpiar archivos auxiliares de LaTeX
    rm -f "${nombre_tex%.tex}.aux" "${nombre_tex%.tex}.log" 2>/dev/null
}

crear_registro(){
    local nombre_tex="$1"
    local id="$2"
    local estado="$3"
    local timestamp="$4"
    local correo="$5"

    local nombre_pdf="${nombre_tex%.tex}.pdf"

    if [ ! -f "$REPORTE_CSV" ]; then
        echo "id;correo;nombre_pdf;estado;timestamp" > "$REPORTE_CSV"
    fi

    echo "$id;$correo;$nombre_pdf;$estado;$timestamp" >> "$REPORTE_CSV"
}

start
