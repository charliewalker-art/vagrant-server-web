#!/bin/bash

# 1. Demander le nom du certificat racine
echo "-------------------------------------------------------"
echo "  CONFIGURATION RÉPONDEUR OCSP (SASA)"
echo "-------------------------------------------------------"
read -p " Entrez le nom du certificat racine (ex: sasa-root) : " CERT_NAME

# Vérification que la saisie n'est pas vide
if [ -z "$CERT_NAME" ]; then
    echo " Erreur: Aucun nom saisi. Fin du script."
    exit 1
fi

# Variables de chemin
BASE_DIR="/var/www/pki_certs/CA"
LOG_FILE="/var/log/ocsp.log"

# 2. Vérifier si les fichiers existent avant de lancer
if [ ! -f "${BASE_DIR}/${CERT_NAME}.crt" ] || [ ! -f "${BASE_DIR}/${CERT_NAME}.key" ]; then
    echo " Erreur: ${CERT_NAME}.crt ou .key introuvable dans ${BASE_DIR}"
    exit 1
fi

# 3. Actions système
echo " Arrêt de l'ancien répondeur OCSP..."
sudo pkill -f "openssl ocsp"

echo " Lancement du répondeur pour ${CERT_NAME} sur le port 2560..."
cd "$BASE_DIR"

# Lancement en arrière-plan avec redirection vers le log
# On utilise les variables pour le certificat, le signataire et la clé
sudo openssl ocsp -index index.txt \
    -CA "${CERT_NAME}.crt" \
    -rsigner "${CERT_NAME}.crt" \
    -rkey "${CERT_NAME}.key" \
    -port 2560 -text >> "$LOG_FILE" 2>&1 &

sleep 2 # Pause pour laisser le temps au port de s'ouvrir

echo " Redémarrage d'Apache..."
sudo systemctl restart apache2

echo "-------------------------------------------------------"
echo " Terminé !"
echo " Répondeur : http://localhost:2560"
echo " Logs : tail -f $LOG_FILE"
echo "-------------------------------------------------------"