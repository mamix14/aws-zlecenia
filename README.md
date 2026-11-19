# Projekt AWS — asynchroniczne przetwarzanie zleceń

Autor: Bartosz Dainowski (91615) · praca indywidualna

## Ustalenia projektu

| Ustalenie | Wartość |
| --- | --- |
| Wariant | **Zamówienia** — `sku` (niepusty tekst) + `quantity` (dodatnia liczba całkowita), decyzja `APPROVED` / `REJECTED` |
| Region | `eu-central-1` (Frankfurt) |
| Środowisko | LocalStack Pro w Dockerze (`compose.yaml`, `ENFORCE_IAM=1`); docelowo to samo w AWS |
| Oznaczanie zasobów | prefiks nazw `bd91615-` + tagi `owner=bd91615`, `project=zlecenia` |
| Bucket danych | `bd91615-zlecenia-dane` (własny, prywatny, Block Public Access włączony) |
| Mój prefiks danych | `bd91615/input/` |
| Prefiks kontrolny | `kontrola/` (poza zakresem roli czytelnika) |

## Lista własnych zasobów

| Zasób | Nazwa | Od lab. |
| --- | --- | --- |
| S3 bucket | `bd91615-zlecenia-dane` | 3 |
| Obiekt S3 (próbka) | `bd91615/input/zlecenia.csv` | 3 |
| Obiekt S3 (kontrolny) | `kontrola/kontrola.csv` | 3 |
| Rola IAM | `bd91615-czytelnik-input` (polityka inline `odczyt-input`) | 3 |

## Tożsamości

- **Wdrażająca (admin)** — przygotowuje bucket, wgrywa pliki, tworzy role. W LocalStack: `arn:aws:iam::000000000000:root`.
- **Czytelnik** — `bd91615-czytelnik-input`, wyłącznie `s3:GetObject` na `bd91615-zlecenia-dane/bd91615/input/*`. Bez `s3:ListBucket`: plik jest odczytywany pod znanym kluczem, więc listowanie nie jest potrzebne (zasada najmniejszych uprawnień).

## Uruchomienie

```bash
# token LocalStack w .env (LOCALSTACK_AUTH_TOKEN=...), plik poza Git
docker compose up -d
python3 -m venv .venv && .venv/bin/pip install awscli
./skrypty/lab3.sh
```

## Laboratoria

| Lab | Wynik | Dowód |
| --- | --- | --- |
| 3. IAM i prywatne S3 | próbka na S3, odczyt dozwolony i odmówiony | [dowody/03-iam-s3.md](dowody/03-iam-s3.md) |
