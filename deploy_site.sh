#!/usr/bin/env bash
# Despliega una carpeta como sitio estatico en S3.
# Uso: ./deploy_site.sh <bucket> <carpeta> [region]
# Idempotente: ejecutarlo dos veces no falla ni duplica nada.
set -euo pipefail

BUCKET="${1:?Uso: $0 <bucket> <carpeta> [region]}"
SRC="${2:?Uso: $0 <bucket> <carpeta> [region]}"
REGION="${3:-$(aws configure get region)}"

[[ -d "$SRC" ]] || { echo "La carpeta '$SRC' no existe"; exit 3; }
aws sts get-caller-identity >/dev/null || { echo "No autenticado. Ejecuta aws configure"; exit 2; }

if aws s3api head-bucket --bucket "$BUCKET" >/dev/null 2>&1; then
  echo "Bucket $BUCKET ya existe, reutilizando"
else
  echo "Creando bucket $BUCKET en $REGION"
  # us-east-1 es la unica region que NO admite LocationConstraint
  if [[ "$REGION" == "us-east-1" ]]; then
    aws s3 mb "s3://$BUCKET"
  else
    aws s3 mb "s3://$BUCKET" --region "$REGION"
  fi
fi

echo "Configurando acceso publico"
aws s3api put-public-access-block --bucket "$BUCKET" \
  --public-access-block-configuration \
  "BlockPublicAcls=false,IgnorePublicAcls=false,BlockPublicPolicy=false,RestrictPublicBuckets=false"

aws s3api put-bucket-policy --bucket "$BUCKET" --policy "$(cat <<JSON
{"Version":"2012-10-17","Statement":[{"Sid":"PublicReadGetObject","Effect":"Allow",
"Principal":"*","Action":"s3:GetObject","Resource":"arn:aws:s3:::$BUCKET/*"}]}
JSON
)"

echo "Sincronizando $SRC"
aws s3 sync "$SRC/" "s3://$BUCKET/" --delete

aws s3 website "s3://$BUCKET/" --index-document index.html --error-document error.html

# El endpoint website usa guion solo en las regiones antiguas; el resto usa punto.
case "$REGION" in
  us-east-1|us-west-1|us-west-2|ap-southeast-1|ap-southeast-2|ap-northeast-1|eu-west-1|sa-east-1)
    WEB_HOST="s3-website-$REGION" ;;
  *)
    WEB_HOST="s3-website.$REGION" ;;
esac

# SITE_URL_OVERRIDE permite apuntar a otro endpoint (p. ej. LocalStack) sin tocar el script
SITE_URL="${SITE_URL_OVERRIDE:-http://$BUCKET.$WEB_HOST.amazonaws.com}"
printf '\n✅ Sitio desplegado: %s\n' "$SITE_URL"
curl -s -o /dev/null -w "   HTTP %{http_code}\n" "$SITE_URL"
