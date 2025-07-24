import csv
import secrets
import string
import argparse
from faker import Faker


def crear_pass_segura(largo = 16):
    """
    Genera una contraseña segura 
    """
    alphabet = (
        string.ascii_lowercase +
        string.ascii_uppercase +
        string.digits +
        string.punctuation
    )
    while True:
        pwd = ''.join(secrets.choice(alphabet) for _ in range(largo))
        # Comprobamos que cumpla la complejidad mínima
        if (any(c.islower() for c in pwd)
            and any(c.isupper() for c in pwd)
            and any(c.isdigit() for c in pwd)
            and any(c in string.punctuation for c in pwd)):
            return pwd

def generar_users_csv(filename, num_users = 10, passwd_largo = 16):
    """
    Genera un archivo CSV con datos de usuarios falsos.
    """
    fake = Faker("es_ES")
    fieldnames = [
        "usuario",
        "nombre_completo",
        "correo",
        "descripcion",
        "password",
        "privilegios",
        "estado"
    ]

    with open(filename, mode="w", newline="", encoding="utf-8") as csvfile:
        writer = csv.DictWriter(csvfile, fieldnames=fieldnames, quotechar='"')
        writer.writeheader()

        for i in range(num_users):
            writer.writerow({
                "usuario":          f"{fake.user_name()}{i}",
                "nombre_completo":  fake.name(),
                "correo":           fake.email(),
                "descripcion":      fake.sentence(nb_words=4),
                "password":         crear_pass_segura(passwd_largo),
                "privilegios":      "Administradores",
                "estado":           "pendiente"
            })

if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description="Genera un CSV de empleados con contraseñas seguras."
    )
    parser.add_argument(
        "num_users",
        type=int,
        nargs="?",
        default=5,
        help="Número de usuarios a generar (por defecto: 5)"
    )
    args = parser.parse_args()
    num_users=args.num_users
    generar_users_csv("empleados.csv", num_users)
    print(f"Archivo 'empleados.csv' generado con {num_users} empleados.")