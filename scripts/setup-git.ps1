# Local git settings for this repo (Windows + vendor/mmi).
# Run once:  powershell -ExecutionPolicy Bypass -File scripts/setup-git.ps1
git config core.protectNTFS false
git config core.autocrlf false
git config core.eol lf
git config core.symlinks false
Write-Host "Set core.protectNTFS=false, core.autocrlf=false, core.eol=lf, core.symlinks=false."
Write-Host ""
Write-Host "If git status fails with 'mmap: could not determine filesize', run from WSL2:"
Write-Host "  bash scripts/break-hardlinks.sh"
Write-Host "  bash scripts/fix-git-index.sh"
Write-Host "  bash scripts/fix-git-index-dirs.sh"
Write-Host "  bash scripts/resolve-case-dups.sh"
