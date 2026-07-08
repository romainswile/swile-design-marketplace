# Gate swile-test : bloque la fin de tour tant qu'un run est en cours sans sentinelle propre.
# Scope : ne fait RIEN si .swile-run.lock est absent du repertoire de travail (aucun impact hors runs swile-test).
# Messages en ASCII volontairement (encodage stdin/stdout Windows).
$ErrorActionPreference = 'SilentlyContinue'

$raw = [Console]::In.ReadToEnd()
$h = $null
try { $h = $raw | ConvertFrom-Json } catch { exit 0 }

# anti-boucle : si deja bloque sans progres, laisser sortir
if ($h -and $h.stop_hook_active) { exit 0 }

$cwd = if ($h -and $h.cwd) { $h.cwd } else { (Get-Location).Path }
$lock = Join-Path $cwd '.swile-run.lock'
if (-not (Test-Path $lock)) { exit 0 }

$sent = Join-Path $cwd '.swile-verify.json'
if (-not (Test-Path $sent)) {
  Write-Output '{"decision":"block","reason":"Run swile-test en cours (.swile-run.lock present) mais AUCUNE sentinelle .swile-verify.json. Le skill exige, pour chaque ecran fini : verify count:0 + compareToSource + textDiff gate + reconcile().ok, puis ecriture de la sentinelle (section 2.6). Execute les passes sur l ecran courant et ecris la sentinelle - ou, si le run est reellement termine, produis le rapport 2.7 puis supprime .swile-run.lock."}'
  exit 0
}

$s = $null
try { $s = Get-Content $sent -Raw | ConvertFrom-Json } catch {
  Write-Output '{"decision":"block","reason":"Sentinelle .swile-verify.json illisible (JSON invalide). Reecris-la au format {ecrans:{...},clean:bool} apres avoir re-execute les passes de verification."}'
  exit 0
}

if ($s.clean -ne $true) {
  Write-Output '{"decision":"block","reason":"Sentinelle .swile-verify.json avec clean:false - au moins un ecran n a pas passe verify count:0 + reconcile().ok + textDiff gate. Termine les verifications de l ecran en cours (ou gate les skips avec l utilisateur), mets la sentinelle a jour, puis conclus."}'
  exit 0
}

exit 0
