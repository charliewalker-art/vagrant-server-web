#!/bin/bash

# 1. Verification des droits root
if [ "$EUID" -ne 0 ]; then
    echo "Erreur: Ce script doit etre execute avec sudo."
    exit 1
fi

echo "-------------------------------------------------------"
echo "CONFIGURATION AUTOMATIQUE APACHE HTTPS"
echo "-------------------------------------------------------"

# 2. Demandes interactives
read -p "Entrez le nom de l'autorite (ex: sasa-root) : " CA_NAME
read -p "Entrez le nom du domaine (ex: naruto.mg) : " DOMAIN

# Verification que les saisies ne sont pas vides
if [ -z "$CA_NAME" ] || [ -z "$DOMAIN" ]; then
    echo "Erreur: L'autorite et le domaine sont obligatoires."
    exit 1
fi

# Extraction du nom court (ex: naruto)
SHORT_NAME=$(echo $DOMAIN | cut -d'.' -f1)

CONF_FILE="/etc/apache2/sites-available/${SHORT_NAME}.conf"
DOC_ROOT="/var/www/${SHORT_NAME}"

echo "Generation de la configuration pour ${DOMAIN}..."

# 3. Creation du fichier de configuration
cat <<EOF > "$CONF_FILE"
<VirtualHost *:443>
    ServerName ${DOMAIN}
    DocumentRoot ${DOC_ROOT}

    SSLEngine on
    # Chemins des certificats
    SSLCertificateFile    /etc/ssl/certs/${DOMAIN}.crt
    SSLCertificateKeyFile /etc/ssl/private/${DOMAIN}.key
    SSLCACertificateFile  /etc/ssl/certs/${CA_NAME}.crt

    # Activation de l'OCSP Stapling
    SSLUseStapling On
    SSLStaplingForceURL http://127.0.0.1:2560

    ErrorLog \${APACHE_LOG_DIR}/${SHORT_NAME}-error.log
    CustomLog \${APACHE_LOG_DIR}/${SHORT_NAME}-access.log combined
</VirtualHost>
EOF

# 4. Gestion des permissions
chown root:root "$CONF_FILE"
chmod 644 "$CONF_FILE"

# Creation du DocumentRoot si il n'existe pas
if [ ! -d "$DOC_ROOT" ]; then
    mkdir -p "$DOC_ROOT"
    chown -R www-data:www-data "$DOC_ROOT"
    echo "Dossier $DOC_ROOT cree."
fi

# 5. Activation du site et test Apache
a2ensite "${SHORT_NAME}.conf" > /dev/null
apache2ctl configtest

if [ $? -eq 0 ]; then
    systemctl reload apache2
    echo "-------------------------------------------------------"
    echo "Configuration activee avec succes pour ${DOMAIN}"
    echo "Certificat utilise : ${DOMAIN}.crt"
    echo "Autorite associee : ${CA_NAME}.crt"
    echo "-------------------------------------------------------"
else
    echo "Erreur dans la configuration Apache. Verifiez les fichiers."
    exit 1
fi