import csv
from faker import Faker




def generate_users_csv(filename, num_users = 10):
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
                "password":         fake.password(length=10),
                "privilegios":      "Administrador",
                "estado":           "creado"
            })

if __name__ == "__main__":
    generate_users_csv("usuarios.csv", num_users=10)
    print("Archivo 'usuarios.csv' generado con 10 usuarios.")