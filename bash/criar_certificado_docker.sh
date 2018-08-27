#!/bin/bash

####################
# https://github.com/thiagotalma/scripts/bash/criar_certificado_docker.sh
####################

set -e
#set -x

regex_email="^[a-z0-9!#\$%&'*+/=?^_\`{|}~-]+(\\.[a-z0-9!#$%&'*+/=?^_\`{|}~-]+)*@([a-z0-9]([a-z0-9-]*[a-z0-9])?\\.)+[a-z0-9]([a-z0-9-]*[a-z0-9])?\$"
regex_domain="^([a-z0-9]([a-z0-9-]*[a-z0-9])?\\.)+[a-z0-9]([a-z0-9-]*[a-z0-9])?\$"

DOMAIN=$1
EMAIL=$2

if [[ -z ${DOMAIN}  || ! ${DOMAIN} =~ $regex_domain || -z $EMAIL || ! $EMAIL =~ $regex_email ]]; then
  echo "Informe o domínio e o email como parâmetros."
  echo "Exemplo: $0 dominio.com email@example.com"
  exit
fi

FOLDER=/opt/docker_proxy/data/certs/${DOMAIN}

[ -f "${FOLDER}.crt" ] && sudo rm -rf "${FOLDER}.crt"
[ -d "${FOLDER}.crt" ] && sudo rm -rf "${FOLDER}"

finish() {
  docker rm -f -v "certbot-${DOMAIN}" >/dev/null 2>&1
}

trap finish EXIT

docker run -d --name "certbot-${DOMAIN}" \
    -e "VIRTUAL_HOST=${DOMAIN}" \
    -e "LETSENCRYPT_EMAIL=$EMAIL" \
    -e "LETSENCRYPT_HOST=$DOMAIN" \
    --network "webproxy" \
    nginx > /dev/null

echo -n "Aguardando"

COUNT=0

while [ ! -f "$FOLDER.crt" ]; do
  if [ $COUNT -gt 60 ]; then 
    finish
    echo "Falha ao gerar o certificado."
    exit 1;
  fi;

  COUNT=$((COUNT+1))
  echo -n "."
  sleep 1
done

finish

echo ""
echo "---------------"
echo "CERTIFICADOS"
echo "---------------"
echo ""
echo "---------------"
echo "$FOLDER.crt"
echo ""
cat "$FOLDER.crt"
echo ""
echo ""
echo "---------------"
echo "$FOLDER.key"
echo ""
cat "$FOLDER.key"