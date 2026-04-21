#!/bin/bash

# 1. Vérification des droits root d'abord
if [ "$EUID" -ne 0 ]; then
    echo "Erreur: Ce script doit être exécuté avec sudo."
    exit 1
fi

# 2. Demande interactive du nom
echo "-------------------------------------------------------"
echo "🛠️  DÉPLOIEMENT DE CERTIFICATS SASA"
echo "-------------------------------------------------------"
read -p " Entrez le nom du certificat (ex: sasa-root) : " CERT_NAME

# Vérification que la saisie n'est pas vide
if [ -z "$CERT_NAME" ]; then
    echo "Erreur: Vous n'avez rien saisi. Fin du script."
    exit 1
fi

# Variables de chemins
SOURCE_DIR="/var/www/pki_certs/CA"
CERT_DEST="/etc/ssl/certs"
KEY_DEST="/etc/ssl/private"

echo ""
echo "Recherche des fichiers pour : ${CERT_NAME}..."

# 3. Traitement du certificat (.crt)
if [ -f "${SOURCE_DIR}/${CERT_NAME}.crt" ]; then
    cp "${SOURCE_DIR}/${CERT_NAME}.crt" "${CERT_DEST}/"
    chown root:root "${CERT_DEST}/${CERT_NAME}.crt"
    chmod 644 "${CERT_DEST}/${CERT_NAME}.crt"
    echo "[CRT] Déplacé dans ${CERT_DEST} (Permissions: 644)"
else
    echo "[CRT] Erreur: ${CERT_NAME}.crt introuvable dans ${SOURCE_DIR}"
fi

# 4. Traitement de la clé privée (.key)
if [ -f "${SOURCE_DIR}/${CERT_NAME}.key" ]; then
    cp "${SOURCE_DIR}/${CERT_NAME}.key" "${KEY_DEST}/"
    chown root:root "${KEY_DEST}/${CERT_NAME}.key"
    chmod 600 "${KEY_DEST}/${CERT_NAME}.key"
    echo "[KEY] Déplacé dans ${KEY_DEST} (Permissions: 600)"
else
    echo "[KEY] Erreur: ${CERT_NAME}.key introuvable dans ${SOURCE_DIR}"
fi

echo "-------------------------------------------------------"
echo "Opération terminée."