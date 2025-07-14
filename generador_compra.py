import csv
from datetime import datetime
import random
from faker import Faker


class GeneradorCompras:
    def __init__(self) -> None:
        self.faker_es = Faker('es_ES')
    
    def generar_compra(self):
        
        compra = {
            "nombre_cliente": self.faker_es.name(),
            "ciudad": self.faker_es.city(),
            "direccion": self.faker_es.address(),
            "correo": self.faker_es.email(),
            "telefono": self.faker_es.phone_number(),
            "ip_compra": self.faker_es.ipv4_public(),
            "monto_total": round(random.uniform(20, 2000), 2),
            "modalidad_pago": random.choice(["completo", "fraccionado"]),
            "estado_pago": random.choice(["exitoso", "fallido"]),
            "timestamp": datetime.now().isoformat()
        }
        return compra
    
    def generar_csv(self):
        name = f"factura_No_{random.random()}.csv"
        csv_path = f'./csv_files/{name}'
        labels = ['nombre_cliente','ciudad','direccion','correo','telefono','ip_compra','monto_total','modalidad_pago','estado_pago','timestamp']
        diccionario = self.generar_compra()
        print(f"{diccionario}")
        with open(csv_path, mode='w',newline='') as file:
            writer = csv.DictWriter(file, fieldnames=labels)
            writer.writeheader()
            writer.writerow(diccionario)
        
        




if __name__ == "__main__":
    generador = GeneradorCompras()
    generador.generar_csv()