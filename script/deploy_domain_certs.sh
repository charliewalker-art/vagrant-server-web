#!/bin/bash

# 1. Vérification des droits root
if [ "$EUID" -ne 0 ]; then
    echo "Erreur: Ce script doit être exécuté avec sudo."
    exit 1
fi

echo "-------------------------------------------------------"
echo "DÉPLOIEMENT DE CERTIFICAT DE DOMAINE"
echo "-------------------------------------------------------"

# 2. Demande interactive du nom de domaine
read -p "Entrez le nom de domaine (ex: rara.mg) : " DOMAIN

if [ -z "$DOMAIN" ]; then
    echo "Erreur: Aucun nom saisi."
    exit 1
fi

# Chemins (Basés sur ton ls /var/www/pki_certs/)
SOURCE_DIR="/var/www/pki_certs"
CERT_DEST="/etc/ssl/certs"
KEY_DEST="/etc/ssl/private"

echo "Traitement pour ${DOMAIN}..."

# 3. Déplacement et configuration du Certificat (.crt)
if [ -f "${SOURCE_DIR}/${DOMAIN}.crt" ]; then
    cp "${SOURCE_DIR}/${DOMAIN}.crt" "${CERT_DEST}/"
    chown root:root "${CERT_DEST}/${DOMAIN}.crt"
    chmod 644 "${CERT_DEST}/${DOMAIN}.crt"
    echo "[CRT] ${DOMAIN}.crt -> ${CERT_DEST} (644)"
else
    echo "[CRT] Fichier introuvable dans ${SOURCE_DIR}"
fi

# 4. Déplacement et configuration de la Clé Privée (.key)
if [ -f "${SOURCE_DIR}/${DOMAIN}.key" ]; then
    cp "${SOURCE_DIR}/${DOMAIN}.key" "${KEY_DEST}/"
    chown root:root "${KEY_DEST}/${DOMAIN}.key"
    chmod 600 "${KEY_DEST}/${DOMAIN}.key"
    echo "[KEY] ${DOMAIN}.key -> ${KEY_DEST} (600)"
else
    echo "[KEY] Fichier introuvable dans ${SOURCE_DIR}"
fi

echo "-------------------------------------------------------"
# 5. Vérification finale automatique
echo " Vérification des permissions :"
ls -l "${CERT_DEST}/${DOMAIN}.crt"
sudo ls -l "${KEY_DEST}/${DOMAIN}.key"
echo "-------------------------------------------------------"