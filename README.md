# Lab 4.1 — Ciclo de vida completo de un bucket S3 con AWS CLI

Automatización del ciclo de vida de un sitio estático en Amazon S3 usando únicamente
AWS CLI v2: crear el bucket, publicar el contenido, exponerlo como website y destruirlo.

**Repositorio:** https://github.com/AaronCoorahua/utec-devops-lab4.1-s3-cli

**Región usada:** `us-east-2` · **Cuenta:** UTEC — DevOps

## Contenido

| Archivo | Descripción |
|---|---|
| `deploy_site.sh` | Despliega una carpeta como sitio estático. **Idempotente**. |
| `cleanup.sh` | Vacía y elimina el bucket. Pide confirmación; sale con 0 si no existe. |
| `site/` | Sitio de demostración (`index.html`, `error.html`, `assets/styles.css`). |
| `iam-policy-minima.json` | Política IAM de mínimo privilegio para ambos scripts (reto). |
| `policy.json` | Politica de bucket de lectura publica (Ejercicio 4). |

## Uso

```bash
export BUCKET="utec-s3-lab-<usuario>-<fecha>"

./deploy_site.sh "$BUCKET" site            # crea o reutiliza el bucket y publica
./deploy_site.sh "$BUCKET" site            # 2a vez: "ya existe, reutilizando"

./cleanup.sh "$BUCKET"                     # vacía y borra (pide confirmación)
./cleanup.sh "$BUCKET"                     # 2a vez: "no existe. Nada que limpiar."
```

Tercer argumento opcional: la región (por defecto `aws configure get region`).

## Nota sobre el endpoint website

El endpoint de website usa **guion** (`s3-website-<region>`) solo en las regiones
antiguas (`us-east-1`, `us-west-1`, `us-west-2`, `ap-southeast-1/2`, `ap-northeast-1`,
`eu-west-1`, `sa-east-1`) y **punto** (`s3-website.<region>`) en el resto.
Como este lab corre en `us-east-2`, `deploy_site.sh` resuelve la forma correcta
automáticamente; el script de la guía, que asume siempre el guion, imprimiría una
URL que no resuelve.

## Mínimo privilegio

`iam-policy-minima.json` es la política mínima que permite ejecutar ambos scripts
sobre buckets con prefijo `utec-s3-lab-*` y nada más. Verificado con un usuario IAM
dedicado: ambos scripts funcionan, y `aws s3 mb s3://otro-nombre`, `aws s3 ls` y
`aws iam list-users` devuelven `AccessDenied`.
