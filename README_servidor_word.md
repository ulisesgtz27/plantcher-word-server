# Servidor Word Expandido - Plantcher

Este servidor Flask permite generar documentos Word (.docx) para todas las modalidades pedagógicas disponibles en Plantcher.

## Modalidades Soportadas

1. **ABJ (Aprendizaje Basado en Juegos)**
   - 4 momentos específicos
   - Enfoque lúdico y participativo

2. **Centros de Interés**
   - 3 momentos específicos
   - Exploración temática

3. **Proyecto**
   - 5 momentos específicos
   - Construcción colaborativa

4. **Rincones de Aprendizaje**
   - 6 momentos específicos
   - Exploración por estaciones

5. **Taller Crítico**
   - 4 momentos específicos
   - Análisis y acción

6. **Unidad Didáctica**
   - 6 momentos específicos
   - Desarrollo curricular integrado

## Instalación

1. **Instalar dependencias:**
```bash
pip install flask python-docx
```

2. **Ejecutar el servidor:**
```bash
python servidor_word_expandido.py
```

El servidor se ejecutará en `http://localhost:5000`

## Uso del API

### Generar Documento Word

**Endpoint:** `POST /generate_word`

**Formato de datos:**
```json
{
  "modalidad": "Nombre de la modalidad",
  "experiencia": "Descripción de la experiencia",
  "nombre_experiencia": "Nombre específico",
  "edad": "Rango de edad",
  "duracion": "Tiempo estimado",
  "numero_ninos": "Cantidad de niños",
  "agente_educativo": "Nombre del educador",
  "momentos": {
    "momento_1": "Descripción del momento 1",
    "momento_2": "Descripción del momento 2",
    // ... según la modalidad
  },
  "materiales": "Lista de materiales necesarios",
  "espacios": "Descripción de espacios requeridos",
  "produccion_sugerida": "Productos esperados",
  "variantes": "Adaptaciones posibles"
}
```

### Obtener Modalidades Disponibles

**Endpoint:** `GET /modalidades`

Retorna la lista de modalidades y sus configuraciones de momentos.

### Verificar Estado del Servidor

**Endpoint:** `GET /health`

Retorna el estado de funcionamiento del servidor.

## Momentos por Modalidad

### ABJ (Aprendizaje Basado en Juegos)
- `planteamiento_juego`: Planteamiento del Juego
- `desarrollo_actividades`: Desarrollo de las Actividades  
- `compartamos_experiencia`: Compartamos la Experiencia
- `comunidad_juego`: Comunidad de Juego

### Centros de Interés
- `contacto_realidad`: En contacto de la realidad
- `identificacion_integracion`: Identificación e integración
- `expresion`: Expresión

### Proyecto
- `punto_partida`: Punto de partida
- `planeacion`: Planeación
- `a_trabajar`: ¡A trabajar!
- `comunicamos_logros`: Comunicamos nuestros logros
- `reflexion_aprendizaje`: Reflexión sobre el aprendizaje

### Rincones de Aprendizaje
- `punto_partida`: Punto de partida (Saberes previos)
- `asamblea_inicial`: Asamblea inicial y planeación
- `exploracion_rincones`: Exploración de los rincones
- `exploracion_descubrimiento`: Exploración y descubrimiento
- `compartimos_aprendido`: Compartimos lo aprendido
- `evaluamos_experiencia`: Evaluamos la experiencia

### Taller Crítico
- `situacion_inicial`: Situación inicial
- `organizacion_acciones`: Organización de las acciones
- `puesta_marcha`: Puesta en marcha
- `valoramos_aprendido`: Valoramos lo aprendido

### Unidad Didáctica
- `lectura_realidad`: Lectura de la realidad
- `identificacion_trama`: Identificación de la trama y complejidad
- `planificacion`: Planificación y organización del trabajo
- `exploracion`: Exploración y descubrimiento
- `participacion`: Participación activa y horizontal
- `conclusion`: Conclusión de la experiencia (Valoración)

## Ejemplo de Uso

```python
import requests

# Datos de ejemplo para ABJ
data = {
    "modalidad": "ABJ",
    "experiencia": "Experiencia matemática",
    "nombre_experiencia": "Jugando con números",
    "edad": "4-5 años",
    "duracion": "45 minutos",
    "numero_ninos": "20",
    "agente_educativo": "María González",
    "momentos": {
        "planteamiento_juego": "Presentamos el juego...",
        "desarrollo_actividades": "Los niños participan...",
        "compartamos_experiencia": "Cada grupo comparte...",
        "comunidad_juego": "Reflexionamos sobre..."
    },
    "materiales": "Tarjetas, objetos para contar",
    "espacios": "Aula amplia",
    "produccion_sugerida": "Libro de números",
    "variantes": "Adaptar dificultad"
}

# Enviar solicitud
response = requests.post('http://localhost:5000/generate_word', json=data)

# Guardar archivo
with open('planificacion.docx', 'wb') as f:
    f.write(response.content)
```

## Pruebas

Ejecutar el archivo de pruebas para verificar todas las modalidades:

```bash
python test_servidor_expandido.py
```

Este script probará automáticamente todas las modalidades con datos de ejemplo.

## Estructura del Documento Generado

Cada documento Word incluye:

1. **Título principal** con modalidad
2. **Subtítulo** con nombre de la experiencia
3. **Tabla de información básica** (modalidad, edad, duración, etc.)
4. **Tabla de momentos específicos** según la modalidad
5. **Tabla de materiales, espacios y producción**

Todos los elementos incluyen formato profesional con:
- Bordes en tablas
- Texto en negrita para etiquetas
- Tamaños de fuente apropiados
- Alineación centrada para títulos

## Integración con Flutter

Para integrar con la aplicación Flutter, enviar una solicitud POST desde Dart:

```dart
final response = await http.post(
  Uri.parse('http://localhost:5000/generate_word'),
  headers: {'Content-Type': 'application/json'},
  body: jsonEncode(data),
);

if (response.statusCode == 200) {
  // Manejar archivo descargado
}
```

## Notas Técnicas

- El servidor utiliza Flask con python-docx para generación de documentos
- Soporte completo para formato Word con tablas y estilos
- Manejo de errores robusto
- Configuración modular para fácil mantenimiento
- Compatible con todas las modalidades de Plantcher
