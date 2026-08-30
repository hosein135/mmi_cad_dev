$repo = "C:\Users\Administrator\Desktop\code\mmi_cad_dev"
$git = "C:\Program Files\Git\bin\git.exe"
$bad = @()
& $git -C $repo ls-files -z | ForEach-Object {
  if ($_ -eq $null) { return }
  foreach ($rel in ($_ -split "`0")) {
    if (-not $rel) { continue }
    $path = Join-Path $repo $rel
    try {
      $item = Get-Item -LiteralPath $path -Force -ErrorAction Stop
      if ($item.LinkType) {
        $bad += "symlink: $rel"
      } else {
        $null = $item.Length
      }
    } catch {
      $bad += "error: $rel :: $($_.Exception.Message)"
    }
  }
}
$bad | Select-Object -First 30
Write-Host "bad_count: $($bad.Count)"
