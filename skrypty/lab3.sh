#!/usr/bin/env bash
# Lab 3 — prywatne S3 + rola z odczytem ograniczonym do własnego prefiksu.
# Uruchom z katalogu repo:  ./skrypty/lab3.sh   (LocalStack musi działać: docker compose up -d)
set -uo pipefail
cd "$(dirname "$0")/.."

export AWS_ACCESS_KEY_ID=test AWS_SECRET_ACCESS_KEY=test AWS_DEFAULT_REGION=eu-central-1
AWS=".venv/bin/aws --endpoint-url=http://localhost:4566"
BUCKET=bd91615-zlecenia-dane
MOJ_KLUCZ=bd91615/input/zlecenia.csv
KONTROLA_KLUCZ=kontrola/kontrola.csv
ROLA=bd91615-czytelnik-input
mkdir -p pobrane

echo "### 1. Przygotowanie danych — tożsamość wdrażająca (admin)"
$AWS sts get-caller-identity --query Arn --output text
$AWS s3api create-bucket --bucket $BUCKET \
  --create-bucket-configuration LocationConstraint=eu-central-1 >/dev/null 2>&1 || true
$AWS s3api put-bucket-tagging --bucket $BUCKET \
  --tagging 'TagSet=[{Key=owner,Value=bd91615},{Key=project,Value=zlecenia}]'
$AWS s3api put-public-access-block --bucket $BUCKET --public-access-block-configuration \
  BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true
echo "Block Public Access:"
$AWS s3api get-public-access-block --bucket $BUCKET --output json
$AWS s3 cp --no-progress dane/zlecenia.csv "s3://$BUCKET/$MOJ_KLUCZ"
$AWS s3 cp --no-progress dane/kontrola.csv "s3://$BUCKET/$KONTROLA_KLUCZ"
echo "Obiekt kontrolny istnieje (head-object jako admin):"
$AWS s3api head-object --bucket $BUCKET --key $KONTROLA_KLUCZ --query '{Rozmiar:ContentLength,Typ:ContentType}' --output json

echo
echo "### 2. Rola czytelnika — tylko s3:GetObject na $BUCKET/bd91615/input/*"
$AWS iam create-role --role-name $ROLA \
  --assume-role-policy-document file://iam/czytelnik-trust.json \
  --tags Key=owner,Value=bd91615 >/dev/null 2>&1 || true
$AWS iam put-role-policy --role-name $ROLA --policy-name odczyt-input \
  --policy-document file://iam/czytelnik-policy.json
CREDS=$($AWS sts assume-role --role-arn arn:aws:iam::000000000000:role/$ROLA \
  --role-session-name lab3-odczyt --query Credentials --output text)
read -r AK EXP SK ST <<<"$CREDS"
export AWS_ACCESS_KEY_ID=$AK AWS_SECRET_ACCESS_KEY=$SK AWS_SESSION_TOKEN=$ST

echo
echo "### 3. Odczyty — ta sama tożsamość czytelnika"
$AWS sts get-caller-identity --query Arn --output text

echo
echo "--- Odczyt A: własny plik s3://$BUCKET/$MOJ_KLUCZ"
$AWS s3api get-object --bucket $BUCKET --key $MOJ_KLUCZ pobrane/zlecenia.csv --query '{Status:`OK`,Rozmiar:ContentLength,ETag:ETag}' --output json
echo "Linie: $(wc -l < pobrane/zlecenia.csv | tr -d ' ') (nagłówek + $(($(wc -l < pobrane/zlecenia.csv) - 1)) rekordów)"
cat pobrane/zlecenia.csv

echo
echo "--- Odczyt B: obiekt kontrolny s3://$BUCKET/$KONTROLA_KLUCZ"
$AWS s3api get-object --bucket $BUCKET --key $KONTROLA_KLUCZ pobrane/kontrola.csv 2>&1
echo "kod wyjścia: $?"
