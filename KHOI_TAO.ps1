$ErrorActionPreference = 'Stop'
Set-Location $PSScriptRoot
if (Test-Path '.env') { Write-Host 'Da co .env. Giu nguyen mat khau.'; exit 0 }
function New-Password {
 $bytes = New-Object byte[] 24
 $rng = [System.Security.Cryptography.RandomNumberGenerator]::Create()
 try { $rng.GetBytes($bytes) } finally { $rng.Dispose() }
 return ([BitConverter]::ToString($bytes)).Replace('-','')
}
$root = New-Password
$wp = New-Password
$monitor = New-Password
$grafana = New-Password
New-Item -ItemType Directory -Force runtime | Out-Null
$utf8 = New-Object System.Text.UTF8Encoding($false)
[IO.File]::WriteAllText((Join-Path $PWD 'runtime/init.sql'), "CREATE USER 'exporter'@'%' IDENTIFIED BY '$monitor' WITH MAX_USER_CONNECTIONS 3;`nGRANT PROCESS, REPLICATION CLIENT, SELECT ON *.* TO 'exporter'@'%';`n", $utf8)
[IO.File]::WriteAllText((Join-Path $PWD 'runtime/exporter.cnf'), "[client]`nhost=mysql`nport=3306`nuser=exporter`npassword=$monitor`n", $utf8)
[IO.File]::WriteAllText((Join-Path $PWD '.env'), "MYSQL_ROOT_PASSWORD=$root`nMYSQL_PASSWORD=$wp`nGRAFANA_PASSWORD=$grafana`n", $utf8)
Write-Host 'Da tao .env va runtime. Xem .env de lay mat khau. Khong dua chung len GitHub.'
