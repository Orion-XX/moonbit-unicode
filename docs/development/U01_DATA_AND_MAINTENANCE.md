# U-01 pinned Unicode inputs

The checked-in inputs under `unicode/data/16.0.0/` are Unicode 16.0.0 data.
`manifest.json` records each upstream URL and SHA-256 digest. `LICENSE.txt`
contains the Unicode license notice; the data must not be replaced by a newer
release without a new task and manifest update.

From the repository root in PowerShell, verify the checkout with:

```powershell
./tools/unicode-gen/verify-data.ps1 -DataPath unicode/data/16.0.0
moon run tools/unicode-gen -- check --data unicode/data/16.0.0
```

For maintenance, download the exact files from the URLs in `manifest.json`,
replace only the intended local files, and run the verifier. It fails closed
with the filename on missing or changed input. To demonstrate the guard without
changing the checkout, copy the directory to a temporary location, alter one
byte, and run the verifier there; do not update a digest to make a modified
file pass.

The normal generator consumes only these checked-in local inputs. U-01 does not
parse UCD records or generate runtime tables; those concerns belong to U-02 and
later cards.
