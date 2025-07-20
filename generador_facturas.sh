#!/bin/bash

start(){
    path=$(python3 generador_compra.py)
    if [ -z "$path" ]; then
        echo "Error: El script python no devolvió una ruta valida"
        exit 1
    fi

    echo "ruta actual $path"
    leer_archivo "$path"
}


leer_archivo(){
    local path="$1"
    echo "ruta actual $path"
    tail -n +2 "$path" | while IFS=";"  read -r id nombre_cliente ciudad direccion correo telefono ip_compra monto_total modalidad_pago estado_pago fecha_emision timestamp
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

    local nombre_factura="./facturas/factura_$id.tex"
    
    echo "nombre de factura $nombre_factura"
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
        ./plantilla_factura_IRSI.tex > "$nombre_factura"

    crear_factura "$nombre_factura" "$id" "$fecha_emision"
    }


crear_factura(){
    local nombre_factura="$1"

    salida=(pdflatex "$nombre_factura")
    crear_registro "$nombre_factura"  "$2" "$3"
}

crear_registro(){
    timestamp1=$(date +"%Y-%m-%d_%H-%M-%S")
    local csv_path="./reporte_facturas/reporte_$timestamp1.csv"
    
    local nombre_factura="$1"
    local id="$2"
    local timestamp="$3"

    if [ ! -f "$csv_path" ]; then
        echo "id;nombre_factura;estado;timpestamp" > "$csv_path"
    fi

    echo "$id;$nombre_factura;"pendiente";$timestamp" >> "$csv_path"

}

start