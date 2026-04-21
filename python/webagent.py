from flask import Flask, request, jsonify
import subprocess
import os

app = Flask(__name__)

# Chemin vers ton dossier de scripts sur le ServerWeb
SCRIPT_DIR = "/opt/scripts"

# --- 1. DEPLOIEMENT DES CERTIFICATS DE DOMAINE ---
@app.route('/api/web/deploy-certs', methods=['POST'])
def deploy_certs():
    data = request.json
    domain = data.get('domain')
    if not domain:
        return jsonify({"status": "error", "message": "Le parametre 'domain' est manquant"}), 400

    script_path = os.path.join(SCRIPT_DIR, "deploy_domain_certs.sh")
    try:
        process = subprocess.run(['sudo', script_path], input=f"{domain}\n", 
                                 capture_output=True, text=True, check=True)
        return jsonify({"status": "success", "output": process.stdout}), 200
    except subprocess.CalledProcessError as e:
        return jsonify({"status": "error", "output": e.stdout, "error_details": e.stderr}), 500

# --- 2. CONFIGURATION APACHE HTTPS ---
@app.route('/api/web/generate-apache', methods=['POST'])
def generate_apache():
    data = request.json
    ca_name = data.get('ca')
    domain = data.get('domain')
    if not ca_name or not domain:
        return jsonify({"status": "error", "message": "Parametres 'ca' et 'domain' requis"}), 400

    script_path = os.path.join(SCRIPT_DIR, "generate_apache_conf.sh")
    try:
        process = subprocess.run(['sudo', script_path], input=f"{ca_name}\n{domain}\n", 
                                 capture_output=True, text=True, check=True)
        return jsonify({"status": "success", "output": process.stdout}), 200
    except subprocess.CalledProcessError as e:
        return jsonify({"status": "error", "output": e.stdout, "error_details": e.stderr}), 500

# --- 3. REDEMARRAGE PKI / REPONDEUR OCSP ---
@app.route('/api/web/restart-pki', methods=['POST'])
def restart_pki():
    data = request.json
    ca_name = data.get('ca')
    if not ca_name:
        return jsonify({"status": "error", "message": "Le parametre 'ca' est requis"}), 400

    script_path = os.path.join(SCRIPT_DIR, "restar_pki.sh")
    try:
        process = subprocess.run(['sudo', script_path], input=f"{ca_name}\n", 
                                 capture_output=True, text=True, check=True)
        return jsonify({"status": "success", "output": process.stdout}), 200
    except subprocess.CalledProcessError as e:
        return jsonify({"status": "error", "output": e.stdout, "error_details": e.stderr}), 500

# --- 4. DEPLOIEMENT CERTIFICAT RACINE (CA) ---
@app.route('/api/web/deploy-ca', methods=['POST'])
def deploy_ca():
    data = request.json
    cert_name = data.get('ca') # ex: sasa-root
    if not cert_name:
        return jsonify({"status": "error", "message": "Le parametre 'ca' est requis"}), 400

    script_path = os.path.join(SCRIPT_DIR, "deploy_certs_interactive.sh")
    try:
        process = subprocess.run(['sudo', script_path], input=f"{cert_name}\n", 
                                 capture_output=True, text=True, check=True)
        return jsonify({"status": "success", "output": process.stdout}), 200
    except subprocess.CalledProcessError as e:
        return jsonify({"status": "error", "output": e.stdout, "error_details": e.stderr}), 500

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5001)