#!/bin/bash

# 1. Verification des droits root
if [ "$EUID" -ne 0 ]; then
    echo "Erreur: Ce script doit etre execute avec sudo."
    exit 1
fi

echo "-------------------------------------------------------"
echo "CONFIGURATION AUTOMATIQUE APACHE HTTPS + CONTENU"
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

# 3. Creation du fichier de configuration Apache
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

    <Directory ${DOC_ROOT}>
        Options Indexes FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>

    ErrorLog \${APACHE_LOG_DIR}/${SHORT_NAME}-error.log
    CustomLog \${APACHE_LOG_DIR}/${SHORT_NAME}-access.log combined
</VirtualHost>
EOF

# 4. Gestion du dossier Web et création du contenu "Bonjour"
if [ ! -d "$DOC_ROOT" ]; then
    mkdir -p "$DOC_ROOT"
    echo "Dossier $DOC_ROOT cree."
fi

# Génération du fichier index.html
cat <<EOF > "${DOC_ROOT}/index.html"
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <title>Bienvenue sur ${DOMAIN}</title>
    <style>
        body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; background-color: #f0f2f5; display: flex; justify-content: center; align-items: center; height: 100vh; margin: 0; }
        .card { background: white; padding: 2rem; border-radius: 15px; shadow: 0 4px 6px rgba(0,0,0,0.1); border-top: 5px solid #2563eb; text-align: center; }
        h1 { color: #1e293b; margin-bottom: 0.5rem; }
        p { color: #64748b; font-size: 1.1rem; }
        .domain { color: #2563eb; font-weight: bold; }
        .status { margin-top: 1rem; font-size: 0.8rem; color: #10b981; font-weight: bold; text-transform: uppercase; }
    </style>
</head>
<body>
    <div class="card">
        <h1>Bonjour ! 👋</h1>
        <p>Bienvenue sur le domaine <span class="domain">${DOMAIN}</span></p>
        <p>Votre serveur Apache est configuré avec succès en <strong>HTTPS</strong>.</p>
        <div class="status">● Serveur Sécurisé</div>
    </div>
</body>
</html>
EOF

# Application des permissions sur tout le dossier web
chown -R www-data:www-data "$DOC_ROOT"
chmod -R 755 "$DOC_ROOT"

# 5. Activation du site et test Apache
a2ensite "${SHORT_NAME}.conf" > /dev/null
apache2ctl configtest

if [ $? -eq 0 ]; then
    systemctl reload apache2
    echo "-------------------------------------------------------"
    echo "Configuration activee avec succes pour ${DOMAIN}"
    echo "Contenu généré dans : ${DOC_ROOT}/index.html"
    echo "-------------------------------------------------------"
else
    echo "Erreur dans la configuration Apache. Verifiez les fichiers."
    exit 1
fi