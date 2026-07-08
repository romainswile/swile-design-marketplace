# Gate swile-design (FALLBACK Windows — le hook officiel est gate.sh, universel).
# Sentinelle .swile-verify.json : etat = en_cours | en_attente_verdict | bloque | fini ; clean = true/false.
# Bloque uniquement : lock sans sentinelle, ou etat en_cours / clean:false. Messages ASCII (encodage Windows).
$ErrorActionPreference = 'SilentlyContinue'
$raw = [Console]::In.ReadToEnd()
$log = Join-Path $env:USERPROFILE '.swile-gate.log'
function W([string]$m){ try { Add-Content -Path $log -Value ("[{0}] ps1 {1}" -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'), $m) } catch {} }
$h = $null
try { $h = $raw | ConvertFrom-Json } catch { W 'stdin illisible'; exit 0 }
if ($h -and $h.stop_hook_active) { W 'skip stop_hook_active'; exit 0 }
$cwd = if ($h -and $h.cwd) { $h.cwd } else { (Get-Location).Path }
W ("invoked cwd=" + $cwd)
$lock = Join-Path $cwd '.swile-run.lock'
if (-not (Test-Path $lock)) { W 'pass no-lock'; exit 0 }
$sent = Join-Path $cwd '.swile-verify.json'
if (-not (Test-Path $sent)) {
  W 'BLOCK lock-sans-sentinelle'
  Write-Output '{"decision":"block","reason":"[swile-design] .swile-run.lock present mais pas de .swile-verify.json : la verification n a pas ete faite. Execute verify() jusqu a count:0 + compareToSource + reconcile(), ecris .swile-verify.json (etat + clean), puis supprime .swile-run.lock si le run est fini."}'
  exit 0
}
$s = $null
try { $s = Get-Content $sent -Raw | ConvertFrom-Json } catch {
  W 'BLOCK sentinelle illisible'
  Write-Output '{"decision":"block","reason":"[swile-design] Sentinelle .swile-verify.json illisible (JSON invalide). Reecris-la : {etat, ecrans:{...}, clean} apres avoir re-execute les passes de verification."}'
  exit 0
}
$etat = if ($s -and $s.etat) { [string]$s.etat } else { '' }
$clean = ($s -and $s.clean -eq $true)
if ($etat -eq 'en_attente_verdict' -or $etat -eq 'bloque') { W ("pass etat=" + $etat); exit 0 }
if ($etat -eq 'fini' -and $clean) { W 'pass fini clean'; exit 0 }
if ($etat -eq '' -and $clean) { W 'pass clean (sentinelle v1)'; exit 0 }
W ("BLOCK etat=" + $(if($etat){$etat}else{'absent'}) + " clean=" + $clean)
Write-Output '{"decision":"block","reason":"[swile-design] Sentinelle .swile-verify.json : ecran non verifie (etat en_cours ou clean:false). Termine la boucle verify() count:0 -> compareToSource -> reconcile, mets a jour la sentinelle (etat en_attente_verdict apres le temoin, fini en fin de run, bloque si panne bridge a signaler), puis reessaie."}'
exit 0
