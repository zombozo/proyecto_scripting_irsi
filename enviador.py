#!/usr/bin/env python3
import csv
import smtplib
import os
import re
import time
from email.message import EmailMessage
from datetime import datetime

# Configuración SMTP (ajusta según tu cuenta Mailtrap o servidor real)
SMTP_SERVER = "sandbox.smtp.mailtrap.io"
SMTP_PORT = 2525
SMTP_USER = "c359d6adf48dd2"
SMTP_PASS = "89cd00df80c9bb"
FROM_EMAIL = "Facturación <facturacion@empresa.com>"
ADMIN_EMAIL = "admin@empresa.com"

# Ruta del CSV que maneja las facturas
REPORTE_CSV = "reporte_facturas/reporte_facturas.csv"

def validar_email(email):
    """Valida formato básico de email."""
    return re.match(r'^[\w\.-]+@[\w\.-]+\.\w+$', email)

def enviar_correo(destinatario, archivo_pdf):
    """Envía correo con el PDF adjunto."""
    try:
        msg = EmailMessage()
        msg['Subject'] = f"Factura {os.path.basename(archivo_pdf)}"
        msg['From'] = FROM_EMAIL
        msg['To'] = destinatario
        msg.set_content("Adjunto encontrará su factura correspondiente.")

        with open(archivo_pdf, 'rb') as f:
            msg.add_attachment(f.read(),
                             maintype='application',
                             subtype='pdf',
                             filename=os.path.basename(archivo_pdf))

        with smtplib.SMTP(SMTP_SERVER, SMTP_PORT) as server:
            server.starttls()
            server.login(SMTP_USER, SMTP_PASS)
            server.send_message(msg)
        return True
    except Exception as e:
        print(f"Error enviando a {destinatario}: {e}")
        return False

def enviar_reporte_admin(exitosos, fallidos):
    """Envía resumen diario al admin con log adjunto."""
    log_diario_path = "logs/log_diario.log"
    try:
        with open(log_diario_path, 'r', encoding='utf-8') as f:
            contenido = f.read()

        msg = EmailMessage()
        msg['Subject'] = f"Reporte Diario de Facturas - {datetime.now().strftime('%Y-%m-%d')}"
        msg['From'] = FROM_EMAIL
        msg['To'] = ADMIN_EMAIL
        msg.set_content(f"""Resumen diario:

Facturas enviadas exitosamente: {exitosos}
Facturas con errores: {fallidos}

Detalles completos en el archivo adjunto.""")

        with open(log_diario_path, 'rb') as f:
            msg.add_attachment(f.read(),
                             maintype='text',
                             subtype='plain',
                             filename='log_diario.log')

        with smtplib.SMTP(SMTP_SERVER, SMTP_PORT) as server:
            server.starttls()
            server.login(SMTP_USER, SMTP_PASS)
            server.send_message(msg)
    except Exception as e:
        print(f"Error enviando reporte al admin: {e}")

def procesar_envios():
    """Lee el CSV, envía las facturas pendientes y actualiza estado."""
    if not os.path.exists(REPORTE_CSV):
        print(f"No existe el archivo {REPORTE_CSV}")
        return

    registros_actualizados = []
    exitosos = 0
    fallidos = 0
    total_procesados = 0

    # Crear carpeta logs si no existe
    os.makedirs("logs", exist_ok=True)
    log_diario_path = "logs/log_diario.log"

    with open(REPORTE_CSV, newline='', encoding='utf-8') as f:
        lector = csv.DictReader(f, delimiter=';')
        campos = lector.fieldnames

        for fila in lector:
            total_procesados += 1
            estado = fila.get('estado', '').strip().lower()

            # Solo enviar las pendientes
            if estado != "pendiente":
                registros_actualizados.append(fila)
                continue

            correo = fila['correo']
            archivo_pdf = fila['nombre_pdf']

            # Validar email y existencia PDF
            if not validar_email(correo):
                print(f"[X] Email inválido: {correo}")
                fila['estado'] = 'fallido'
                fallidos += 1
                registros_actualizados.append(fila)
                continue

            if not os.path.exists(archivo_pdf):
                print(f"[X] Archivo no encontrado: {archivo_pdf}")
                fila['estado'] = 'fallido'
                fallidos += 1
                registros_actualizados.append(fila)
                continue

            # Enviar correo
            if enviar_correo(correo, archivo_pdf):
                print(f"[✓] Enviado a {correo}")
                fila['estado'] = 'exitoso'
                exitosos += 1
            else:
                print(f"[X] Falló envío a {correo}")
                fila['estado'] = 'fallido'
                fallidos += 1

            registros_actualizados.append(fila)

            # Esperar 1 segundo para evitar límite de Mailtrap
            time.sleep(1)

    # Sobrescribir CSV con estados actualizados
    with open(REPORTE_CSV, 'w', newline='', encoding='utf-8') as f:
        escritor = csv.DictWriter(f, fieldnames=campos, delimiter=';')
        escritor.writeheader()
        escritor.writerows(registros_actualizados)

    # Log diario
    with open(log_diario_path, 'a', encoding='utf-8') as f:
        f.write(f"\n=== Reporte de Envíos {datetime.now().strftime('%Y-%m-%d %H:%M:%S')} ===\n")
        f.write(f"Total procesados: {total_procesados}\n")
        f.write(f"Envíos exitosos: {exitosos}\n")
        f.write(f"Envíos fallidos: {fallidos}\n")
        f.write("="*50 + "\n")

    # Enviar reporte al admin
    enviar_reporte_admin(exitosos, fallidos)

if __name__ == "__main__":
    procesar_envios()
