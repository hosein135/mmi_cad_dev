# Local git settings for this repo (Windows + vendor/mmi).
# Run once:  powershell -ExecutionPolicy Bypass -File scripts/setup-git.ps1
git config core.protectNTFS false
Write-Host "Set core.protectNTFS=false for this repo."
Write-Host ""
Write-Host "If git status fails with 'mmap: could not determine filesize', run from WSL:"
Write-Host "  bash scripts/break-hardlinks.sh"
Write-Host "  bash scripts/fix-git-index.sh"
Write-Host "  bash scripts/fix-git-index-dirs.sh"
Write-Host "  bash scripts/resolve-case-dups.sh"
