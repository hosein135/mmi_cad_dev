First run: put **`mmi_pd_040526.tar.gz`** here, then `./run.sh --prep-only`.

That unpacks and flattens the tree (`max/`, `sue/`, `bin/` instead of i486/versioned names), keeps Unix **source** under `~/.cache/mmi-cad/vendor` (WSL ext4 — NTFS cannot store that tree), copies the **runtime** tree to **`vendor/mmi/`**, and **deletes the tarball**.

After compile, `vendor/mmi/bin` holds the x86_64 tools. `vendor/mmi` is gitignored.
