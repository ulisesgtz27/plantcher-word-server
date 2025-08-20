# Servidor Plantcher Word - Backend

Este es el servidor Python Flask que genera documentos Word para la aplicación Plantcher.

## Estructura del Backend

- `app.py` - Aplicación Flask principal
- `requirements.txt` - Dependencias Python
- `Procfile` - Configuración para despliegue
- `railway.json` - Configuración específica de Railway

## Modalidades Soportadas

- ABJ (Aprendizaje Basado en Juegos)
- Centros de Aprendizaje
- Talleres
- Rincones de Aprendizaje
- Proyecto
- Unidad Didáctica

## API Endpoints

- `GET /` - Verificar estado del servidor
- `GET /test` - Prueba de conectividad
- `POST /test-post` - Prueba de solicitudes POST
- `GET /modalidades` - Lista de modalidades disponibles
- `POST /generar-word` - Generar documento Word

## Desarrollo Local

```bash
pip install -r requirements.txt
python app.py
```

## Despliegue

Este backend está configurado para desplegarse automáticamente en Railway cuando se hace push al repositorio.
