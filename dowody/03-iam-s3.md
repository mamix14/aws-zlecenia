# Lab 3 — IAM i prywatne dane w S3 (dowód)

**Rola użyta do obu odczytów:** `bd91615-czytelnik-input`
(sesja `arn:aws:sts::000000000000:assumed-role/bd91615-czytelnik-input/lab3-odczyt`)

**Różnica prefiksów:**
- `bd91615/input/` — mój prefiks; polityka roli zezwala na `s3:GetObject` na `bd91615-zlecenia-dane/bd91615/input/*` → odczyt dozwolony.
- `kontrola/` — osobny prefiks w tym samym buckecie; żadna polityka roli go nie obejmuje → `AccessDenied`.

Obiekt kontrolny **istnieje** — potwierdzone `head-object` tożsamością wdrażającą (admin) przed próbą
(rozmiar 94 B, pełny zapis w [03-odczyty-raw.txt](03-odczyty-raw.txt)), więc odmowa wynika z uprawnień, a nie z błędnego klucza.
Bucket ma włączone wszystkie cztery ustawienia Block Public Access.

## Oba odczyty — ta sama tożsamość

```text
$ aws sts get-caller-identity --query Arn --output text
arn:aws:sts::000000000000:assumed-role/bd91615-czytelnik-input/lab3-odczyt

--- Odczyt A: własny plik s3://bd91615-zlecenia-dane/bd91615/input/zlecenia.csv
$ aws s3api get-object --bucket bd91615-zlecenia-dane --key bd91615/input/zlecenia.csv pobrane/zlecenia.csv
{
    "Status": "OK",
    "Rozmiar": 379,
    "ETag": "\"28994f7e5c083c8d2466e12e923b0ea8\""
}
Linie: 13 (nagłówek + 12 rekordów)
caseId,group,scenario,sku,quantity
O01,standard,normal,SKU-A,1
...
O12,retry,transient_once,SKU-B,2

--- Odczyt B: obiekt kontrolny s3://bd91615-zlecenia-dane/kontrola/kontrola.csv
$ aws s3api get-object --bucket bd91615-zlecenia-dane --key kontrola/kontrola.csv pobrane/kontrola.csv
An error occurred (AccessDenied) when calling the GetObject operation: User: arn:aws:sts::000000000000:assumed-role/bd91615-czytelnik-input/lab3-odczyt is not authorized to perform: s3:GetObject on resource: "arn:aws:s3:::bd91615-zlecenia-dane/kontrola/kontrola.csv" because no identity-based policy allows the s3:GetObject action
kod wyjścia: 255
```

## Decyzje

- **Bez listowania.** Rola zna dokładny klucz pliku, więc dostała tylko `s3:GetObject`. `s3:ListBucket` to osobna operacja na buckecie (nie na obiekcie); gdyby była potrzebna, ograniczyłbym ją warunkiem `s3:prefix = bd91615/input/`.
- **Dwie tożsamości.** Dane przygotowuje tożsamość wdrażająca (szersze uprawnienia), odczyty wykonuje wyłącznie rola czytelnika — porównanie dotyczy tej samej tożsamości.
- **Środowisko.** LocalStack Pro z `ENFORCE_IAM=1`, dzięki czemu polityki IAM są sprawdzane jak w AWS. Konto `000000000000` to domyślne konto emulatora.

Pliki: [polityka roli](../iam/czytelnik-policy.json), [zaufanie roli](../iam/czytelnik-trust.json), [skrypt](../skrypty/lab3.sh), [próbka](../dane/zlecenia.csv).
