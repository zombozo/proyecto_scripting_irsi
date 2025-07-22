import csv
from datetime import datetime
import random
from faker import Faker
import pandas as pd


class GeneradorCompras:
    def __init__(self) -> None:
        self.faker_es = Faker('es_ES')
    
    def generar_compra(self):
        compras = []
        for i in range(10):
            compra = {
                "id": self.faker_es.uuid4() ,
                "nombre_cliente": self.faker_es.name(),
                "ciudad": self.faker_es.city(),
                "direccion": self.faker_es.address().replace("\n"," "),
                "correo": self.faker_es.email(),
                "telefono": self.faker_es.phone_number(),
                "ip_compra": self.faker_es.ipv4_public(),
                "monto_total": round(random.uniform(20, 2000), 2),
                "modalidad_pago": random.choice(["completo", "fraccionado"]),
                "estado_pago": random.choice(["exitoso", "fallido"]),
                "fecha_emision": self.faker_es.date(),
                "timestamp": datetime.now().isoformat()
            }
            compras.append(compra)
        return compras
    
    def generar_csv(self):
        name = f"factura_No_{int(datetime.now().timestamp())}.csv"
        csv_path = f'./csv_files/{name}'
        
        compras = self.generar_compra()
        dataframe = pd.DataFrame(compras)
        dataframe.to_csv(csv_path,sep=';',index=False)
        return csv_path
        
    
    
            
            
    
        
        




if __name__ == "__main__":
    generador = GeneradorCompras()
    path = generador.generar_csv()
    print(path)