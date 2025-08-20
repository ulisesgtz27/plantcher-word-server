from flask import Flask
import os

app = Flask(__name__)

@app.route('/')
def home():
    return {"status": "OK", "message": "Servidor Railway funcionando", "port": os.environ.get('PORT', '5000')}

@app.route('/test')
def test():
    return {"status": "OK", "test": "successful"}

if __name__ == '__main__':
    port = int(os.environ.get('PORT', 5000))
    print(f"🚀 Servidor simple iniciando en puerto {port}")
    app.run(host='0.0.0.0', port=port, debug=False)
