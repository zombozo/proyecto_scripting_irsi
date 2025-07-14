#!/bin/bash

leer_archivo(){
    tail -n +2 /home/zombozo/proyectos/scripting_irsi/csv_files/factura_No_0.7205665821357018.csv | \
    while IFS=","  read -r nombre_cliente ciudad direccion correo telefono ip_compra monto_total modalidad_pago estado_pago timestamp
    do 
        echo "$nombre_cliente"
        reemplazar_factura "$nombre_cliente" "$ciudad $direccion" "$correo" "$telefono" "$ip_compra" "$monto_total" "$modalidad_pago" "$estado_pago" "$timestamp"
    done < /home/zombozo/proyectos/scripting_irsi/csv_files/factura_No_0.7205665821357018.csv
    }

reemplazar_factura(){
    sed -e "s/nombre/$nombre_cliente/g" -e "s/correo/$correo/g" -e "s/telefono/$telefono/g" -e "s/direccion/$direccion/g" -e "s/ciudad/$direccion/g" -e "s/cantidad/$monto_total/g"  -e "s/monto/$monto_total/g" -e "s/pago/$modalidad_pago/g" -e "s/estado_pago/$estado_pago/g" -e "s/ip/$ip_compra/g" -e "s/timestamp/$timestamp/g"  ./plantilla_factura_IRSI.tex > factura_irsi.tex
    }

leer_archivo
