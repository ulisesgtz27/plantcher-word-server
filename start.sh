#!/bin/bash
echo "🚀 Iniciando servidor en Railway..."
echo "📦 Puerto: $PORT"
echo "🐍 Versión Python: $(python --version)"
echo "📋 Archivos disponibles:"
ls -la
echo "🧪 Probando servidor simple primero..."
python servidor_simple.py
