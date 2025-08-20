"""
Script para probar el servidor en Windows usando Waitress
Ejecutar: python test_windows.py
"""
from waitress import serve
from servidor_word_final import app
import os

if __name__ == '__main__':
    port = int(os.environ.get('PORT', 5000))
    print("🚀 SERVIDOR PLANTCHER WORD - PRUEBA WINDOWS")
    print(f"📍 Servidor ejecutándose en puerto: {port}")
    print("🔗 Rutas disponibles:")
    print("   POST /generar-word - Generar documento Word")
    print("   GET  /test        - Prueba de conectividad")
    print("   POST /test-post   - Prueba de solicitudes POST")
    print("   GET  /modalidades - Lista de modalidades")
    print(f"🌐 Accede en: http://localhost:{port}")
    print("⏹️  Presiona Ctrl+C para detener")
    
    serve(app, host='0.0.0.0', port=port)
