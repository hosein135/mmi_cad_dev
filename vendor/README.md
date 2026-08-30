**`vendor/mmi/`** is the extracted CAD tree (in git): flattened names, `src/`, and x86_64 tools in `bin/`.

To rebuild from the original archive instead, put **`mmi_pd_040526.tar.gz`** here and run `./run.sh --prep-only` (that unpacks into `vendor/mmi` and deletes the tarball).

`vendor/result` is a Nix symlink and is not committed.
