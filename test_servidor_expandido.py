import requests
import json

# URL del servidor
SERVER_URL = "http://localhost:5000"

# Ejemplos de datos para cada modalidad
ejemplos_modalidades = {
    "ABJ": {
        "modalidad": "ABJ",
        "experiencia": "Experiencia de prueba ABJ",
        "nombre_experiencia": "Jugando con los números",
        "edad": "4-5 años",
        "duracion": "45 minutos",
        "numero_ninos": "20",
        "agente_educativo": "María González",
        "momentos": {
            "planteamiento_juego": "Presentamos el juego de números donde los niños deberán encontrar las parejas numéricas.",
            "desarrollo_actividades": "Los niños participan activamente buscando parejas, contando objetos y resolviendo retos numéricos simples.",
            "compartamos_experiencia": "Cada grupo comparte sus estrategias y descubrimientos durante el juego.",
            "comunidad_juego": "Reflexionamos sobre lo aprendido y cómo el juego nos ayudó a entender mejor los números."
        },
        "materiales": "Tarjetas numéricas, objetos para contar, tableros de juego",
        "espacios": "Aula amplia con mesas y espacio libre para moverse",
        "produccion_sugerida": "Creación de un libro de números ilustrado por los niños",
        "variantes": "Adaptar la dificultad según el nivel de cada grupo"
    },
    
    "Centros de Interés": {
        "modalidad": "Centros de Interés",
        "experiencia": "Los animales de mi entorno",
        "nombre_experiencia": "Descubriendo el mundo animal",
        "edad": "3-4 años",
        "duracion": "60 minutos",
        "numero_ninos": "15",
        "agente_educativo": "Ana Rodríguez",
        "momentos": {
            "contacto_realidad": "Observamos y exploramos imágenes y sonidos de diferentes animales del entorno.",
            "identificacion_integracion": "Identificamos características, hábitats y sonidos de cada animal, relacionándolos con nuestras experiencias.",
            "expresion": "Representamos nuestros animales favoritos a través de dibujos, imitaciones y cuentos."
        },
        "materiales": "Imágenes de animales, grabaciones de sonidos, materiales de arte",
        "espacios": "Aula con rincones temáticos y espacio para expresión corporal",
        "produccion_sugerida": "Mural colectivo de animales y libro de sonidos",
        "variantes": "Incluir animales de diferentes hábitats según el interés del grupo"
    },
    
    "Proyecto": {
        "modalidad": "Proyecto",
        "experiencia": "Construyendo nuestro jardín",
        "nombre_experiencia": "El jardín de los sueños",
        "edad": "4-5 años",
        "duracion": "90 minutos",
        "numero_ninos": "18",
        "agente_educativo": "Carlos Méndez",
        "momentos": {
            "punto_partida": "¿Qué sabemos sobre las plantas y cómo crecen? Exploramos nuestros conocimientos previos.",
            "planeacion": "Diseñamos nuestro jardín: qué plantas queremos, dónde las ubicaremos y qué necesitamos.",
            "a_trabajar": "Preparamos la tierra, sembramos semillas y organizamos el cuidado diario.",
            "comunicamos_logros": "Presentamos nuestro jardín a otras familias y explicamos nuestro proceso.",
            "reflexion_aprendizaje": "Reflexionamos sobre lo que aprendimos del crecimiento y cuidado de las plantas."
        },
        "materiales": "Semillas, tierra, macetas, regaderas, herramientas de jardinería infantiles",
        "espacios": "Patio exterior y aula para planificación",
        "produccion_sugerida": "Jardín funcional y diario del crecimiento de las plantas",
        "variantes": "Adaptar tipos de plantas según la temporada y el clima"
    },
    
    "Rincones de Aprendizaje": {
        "modalidad": "Rincones de Aprendizaje",
        "experiencia": "Explorando el mundo de las profesiones",
        "nombre_experiencia": "¿Qué quiero ser cuando crezca?",
        "edad": "4-5 años",
        "duracion": "75 minutos",
        "numero_ninos": "16",
        "agente_educativo": "Laura Jiménez",
        "momentos": {
            "punto_partida": "¿Qué profesiones conocemos? Compartimos lo que sabemos sobre diferentes trabajos.",
            "asamblea_inicial": "Planificamos la exploración de rincones: médico, cocinero, constructor, artista.",
            "exploracion_rincones": "Rotamos por diferentes rincones profesionales, experimentando roles y herramientas.",
            "exploracion_descubrimiento": "Descubrimos habilidades específicas y herramientas de cada profesión.",
            "compartimos_aprendido": "Presentamos lo que aprendimos en cada rincón profesional.",
            "evaluamos_experiencia": "Reflexionamos sobre qué profesión nos gustó más y por qué."
        },
        "materiales": "Disfraces, herramientas de juguete, materiales específicos por profesión",
        "espacios": "Aula organizada en 4 rincones temáticos",
        "produccion_sugerida": "Álbum de profesiones con dibujos y descripciones de los niños",
        "variantes": "Incluir profesiones del entorno local y familiar"
    },
    
    "Taller Crítico": {
        "modalidad": "Taller Crítico",
        "experiencia": "Cuidado del medio ambiente",
        "nombre_experiencia": "Guardianes de la naturaleza",
        "edad": "5-6 años",
        "duracion": "80 minutos",
        "numero_ninos": "14",
        "agente_educativo": "Roberto Silva",
        "momentos": {
            "situacion_inicial": "Observamos y analizamos problemáticas ambientales de nuestro entorno inmediato.",
            "organizacion_acciones": "Planificamos acciones concretas para contribuir al cuidado ambiental.",
            "puesta_marcha": "Implementamos nuestras acciones: reciclaje, cuidado de plantas, ahorro de agua.",
            "valoramos_aprendido": "Evaluamos el impacto de nuestras acciones y reflexionamos sobre ser guardianes."
        },
        "materiales": "Materiales reciclables, plantas, contenedores de separación",
        "espacios": "Aula, patio y espacios comunes del centro educativo",
        "produccion_sugerida": "Campaña de sensibilización ambiental y sistema de reciclaje",
        "variantes": "Adaptar problemáticas según el contexto local"
    },
    
    "Unidad Didáctica": {
        "modalidad": "Unidad Didáctica",
        "experiencia": "Las tradiciones de mi familia",
        "nombre_experiencia": "Tejiendo historias familiares",
        "edad": "4-5 años",
        "duracion": "70 minutos",
        "numero_ninos": "17",
        "agente_educativo": "Isabel Torres",
        "momentos": {
            "lectura_realidad": "Exploramos las tradiciones familiares que cada niño trae de casa.",
            "identificacion_trama": "Identificamos similitudes y diferencias entre las tradiciones familiares.",
            "planificacion": "Organizamos cómo vamos a conocer y compartir nuestras tradiciones.",
            "exploracion": "Exploramos diferentes tradiciones a través de objetos, comidas, música.",
            "participacion": "Participamos activamente recreando tradiciones y creando nuevas.",
            "conclusion": "Valoramos la riqueza de nuestras diferencias culturales y tradiciones."
        },
        "materiales": "Objetos tradicionales, instrumentos musicales, materiales de arte",
        "espacios": "Aula y espacios para presentaciones familiares",
        "produccion_sugerida": "Libro de tradiciones familiares y festival cultural",
        "variantes": "Incluir tradiciones de diferentes culturas presentes en el grupo"
    }
}

def probar_modalidad(modalidad):
    """Prueba la generación de Word para una modalidad específica"""
    print(f"\n=== Probando modalidad: {modalidad} ===")
    
    data = ejemplos_modalidades[modalidad]
    
    try:
        response = requests.post(f"{SERVER_URL}/generate_word", json=data)
        
        if response.status_code == 200:
            # Guardar el archivo
            filename = f"prueba_{modalidad.lower().replace(' ', '_')}.docx"
            with open(filename, 'wb') as f:
                f.write(response.content)
            print(f"✅ Archivo generado: {filename}")
            return True
        else:
            print(f"❌ Error {response.status_code}: {response.text}")
            return False
            
    except requests.exceptions.ConnectionError:
        print("❌ No se puede conectar al servidor. ¿Está ejecutándose?")
        return False
    except Exception as e:
        print(f"❌ Error: {e}")
        return False

def probar_endpoint_modalidades():
    """Prueba el endpoint de modalidades disponibles"""
    print("\n=== Probando endpoint de modalidades ===")
    
    try:
        response = requests.get(f"{SERVER_URL}/modalidades")
        
        if response.status_code == 200:
            data = response.json()
            print("✅ Modalidades disponibles:")
            for modalidad in data['modalidades']:
                print(f"  - {modalidad}")
            return True
        else:
            print(f"❌ Error {response.status_code}: {response.text}")
            return False
            
    except requests.exceptions.ConnectionError:
        print("❌ No se puede conectar al servidor. ¿Está ejecutándose?")
        return False
    except Exception as e:
        print(f"❌ Error: {e}")
        return False

def main():
    print("🧪 PRUEBAS DEL SERVIDOR WORD EXPANDIDO")
    print("=" * 50)
    
    # Probar endpoint de modalidades
    if not probar_endpoint_modalidades():
        print("\n❌ Fallo en endpoint básico. Verificar servidor.")
        return
    
    # Probar cada modalidad
    exitosos = 0
    total = len(ejemplos_modalidades)
    
    for modalidad in ejemplos_modalidades.keys():
        if probar_modalidad(modalidad):
            exitosos += 1
    
    print(f"\n📊 RESUMEN")
    print(f"Modalidades probadas: {total}")
    print(f"Exitosas: {exitosos}")
    print(f"Fallidas: {total - exitosos}")
    
    if exitosos == total:
        print("🎉 ¡Todas las modalidades funcionan correctamente!")
    else:
        print("⚠️  Algunas modalidades presentaron errores.")

if __name__ == "__main__":
    main()
