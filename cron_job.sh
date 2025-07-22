#!/bin/bash


DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Ejecución inicial
echo "[*] Ejecutando generación y envío inicial..."
source "$DIR/venv/bin/activate"
bash "$DIR/generador_facturas.sh"
"$DIR/venv/bin/python3" "$DIR/enviador.py"

# Configurar cron si no existe
if ! crontab -l 2>/dev/null | grep -q "generador_facturas.sh"; then
    (crontab -l 2>/dev/null; echo "0 10 * * * cd $DIR && source venv/bin/activate && bash generador_facturas.sh && venv/bin/python3 enviador.py >> envio_log.txt 2>&1") | crontab -
    echo "[✓] Cron registrado para ejecutarse diariamente a las 10 AM."
else
    echo "[✓] Cron ya estaba registrado."
fi