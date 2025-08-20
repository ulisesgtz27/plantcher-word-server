# Servidor Word Plantcher

Servidor Flask para generar documentos Word de todas las modalidades pedagógicas de Plantcher.

## Modalidades soportadas:
- ABJ (Aprendizaje Basado en Juegos)
- Centros de Interés
- Proyecto
- Rincones de Aprendizaje
- Taller Crítico
- Unidad Didáctica

## Archivos del servidor:
- `servidor_word_final.py` - Servidor Flask principal
- `requirements.txt` - Dependencias Python
- `Procfile` - Configuración para despliegue
- `runtime.txt` - Versión de Python

## API Endpoints:
- `POST /generar-word` - Generar documento Word
- `GET /test` - Prueba de conectividad
- `GET /modalidades` - Lista de modalidades disponibles

## Deployment:
Desplegado en Railway.app para funcionar 24/7 en la nube.
