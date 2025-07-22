import csv
import smtplib
import os
from email.message import EmailMessage
import re

# Configuración SMTP de Mailtrap
SMTP_SERVER = "sandbox.smtp.mailtrap.io"
SMTP_PORT = 2525
EMAIL_USER = "775e28187f3f55"
EMAIL_PASS = "eaceeb46a5e3ef"
FROM_EMAIL = "Facturación <facturacion@ejemplo.com>"

def es_email_valido(email):
    return re.match(r"[^@]+@[^@]+\.[^@]+", email)

def enviar_factura(destinatario, archivo_pdf):
    mensaje = EmailMessage()
    mensaje['Subject'] = "Tu factura en PDF"
    mensaje['From'] = FROM_EMAIL
    mensaje['To'] = destinatario
    mensaje.set_content("Hola,\n\nAdjunto encontrarás tu factura en PDF.")

    with open(archivo_pdf, 'rb') as f:
        mensaje.add_attachment(f.read(), maintype='application', subtype='pdf', filename=os.path.basename(archivo_pdf))

    try:
        with smtplib.SMTP(SMTP_SERVER, SMTP_PORT) as server:
            server.starttls()
            server.login(EMAIL_USER, EMAIL_PASS)
            server.send_message(mensaje)
        return True
    except Exception as e:
        print(f"[X] Error al enviar a {destinatario}: {e}")
        return False

def enviar_facturas(csv_path):
    registros = []

    with open(csv_path, newline='', encoding='utf-8') as csvfile:
        lector = csv.DictReader(csvfile, delimiter=';')
        for fila in lector:
            correo = fila['correo']
            archivo_pdf = os.path.join("facturas", fila['nombre_pdf'])  # Aquí se concatena la carpeta facturas
            estado = fila['estado']

            if estado.strip().lower() == "enviado":
                registros.append(fila)
                continue

            if not es_email_valido(correo):
                print(f"[X] Correo inválido: {correo}")
                registros.append(fila)
                continue

            if not os.path.exists(archivo_pdf):
                print(f"[X] Archivo no encontrado: {archivo_pdf}")
                registros.append(fila)
                continue

            if enviar_factura(correo, archivo_pdf):
                print(f"[✓] Correo enviado a {correo}")
                fila['estado'] = 'enviado'
            else:
                print(f"[X] No se pudo enviar a {correo}")

            registros.append(fila)

    # Guardar el CSV actualizado con todas las columnas existentes
    if registros:
        campos = registros[0].keys()  # Para conservar todas las columnas
    else:
        campos = ['id','correo','nombre_pdf','estado','timestamp']

    with open(csv_path, 'w', newline='', encoding='utf-8') as csvfile:
        escritor = csv.DictWriter(csvfile, fieldnames=campos, delimiter=';')
        escritor.writeheader()
        escritor.writerows(registros)

if __name__ == "__main__":
    enviar_facturas("reporte_facturas/reporte_facturas.csv")
