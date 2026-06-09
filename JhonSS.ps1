# =========================================================================
# VALIDAÇÃO DE ADMINISTRADOR
# =========================================================================
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Clear-Host
    Write-Warning "========================================================="
    Write-Warning " ERRO: O script PRECISA ser executado como Administrador!"
    Write-Warning "========================================================="
    Exit
}

# Caminho do relatório
$outputPath = "$env:LOCALAPPDATA\Temp\Relatorio_SS_Elite.txt"

# [CORREÇÃO] Remove o arquivo antigo para o Windows não bugar o encoding do novo
if (Test-Path $outputPath) { 
    Remove-Item $outputPath -Force -ErrorAction SilentlyContinue 
}

$lines = @()

# Cabeçalho
$lines += "==================================================="
$lines += "       RELATORIO DE INVESTIGACAO - STAFF FIVEM     "
$lines += "==================================================="
$lines += " Desenvolvido por: Jhon"
$lines += " Data/Hora: $((Get-Date).ToString('dd/MM/yyyy HH:mm:ss'))"
$lines += "==================================================="
$lines += ""

# 1. Processos
$lines += "1. PROCESSOS SUSPEITOS OU ATIVOS"
$lines += "---------------------------------------------------"
$lines += "{0,-8} {1,-25} {2}" -f "PID", "Nome do Processo", "Caminho do Executavel"
$lines += "{0,-8} {1,-25} {2}" -f "---", "----------------", "---------------------"

$processes = Get-Process -ErrorAction SilentlyContinue | Sort-Object Name
foreach ($p in $processes) {
    $pPath = "Acesso Negado / Protegido"
    try {
        if ($p.MainModule.FileName) { $pPath = $p.MainModule.FileName }
    } catch {}
    
    $lines += "{0,-8} {1,-25} {2}" -f $p.Id, $p.Name, $pPath
}
$lines += ""

# 2. Conexões de Rede
$lines += "2. CONEXOES DE REDE ATIVAS (IPs E PORTAS)"
$lines += "---------------------------------------------------"
$connections = Get-NetTCPConnection -State Established -ErrorAction SilentlyContinue
foreach ($conn in $connections) {
    $lines += "PID: $($conn.OwningProcess) | Local: $($conn.LocalAddress):$($conn.LocalPort) -> Remoto: $($conn.RemoteAddress):$($conn.RemotePort)"
}
$lines += ""

# 3. Arquivos Modificados (Apenas na Temp para evitar sobrecarga)
$lines += "3. ARQUIVOS MODIFICADOS NAS ULTIMAS 2 HORAS (PASTA TEMP)"
$lines += "---------------------------------------------------"
$twoHoursAgo = (Get-Date).AddHours(-2)
$files = Get-ChildItem -Path "$env:LOCALAPPDATA\Temp" -File -Recurse -ErrorAction SilentlyContinue | 
         Where-Object { $_.LastWriteTime -gt $twoHoursAgo } | Sort-Object LastWriteTime

foreach ($f in $files) {
    $lines += "[$($f.LastWriteTime.ToString('HH:mm:ss'))] $($f.FullName)"
}
$lines += ""

# 4. Diagnóstico Automático
$lines += "4. DIAGNOSTICO AUTOMATICO DE SUSPEITAS"
$lines += "---------------------------------------------------"

$alerts = @()
foreach ($p in $processes) {
    $pPath = ""
    try { if ($p.MainModule.FileName) { $pPath = $p.MainModule.FileName } } catch {}
    
    if ($pPath -and ($pPath -like "*\AppData\*" -or $pPath -like "*\Temp\*")) {
        if ($pPath -notlike "*\AppData\Roaming\Spotify\*") {
            $alerts += "[ALERTA] Processo em pasta suspeita: $($p.Name) -> Caminho: $pPath"
        }
    }
}

if ($alerts.Count -gt 0) {
    $lines += "ATENCAO: Foram detectados indicios suspeitos!"
    $lines += "---------------------------------------------------"
    foreach ($alert in $alerts) { $lines += $alert }
} else {
    $lines += "Nenhum indicio grave detectado automaticamente nos caminhos de execucao."
}

# Salva usando criptografia pura do sistema para evitar herança de lixo
[System.IO.File]::WriteAllLines($outputPath, $lines, [System.Text.Encoding]::UTF8)

# Mensagens de finalização
Write-Host ""
Write-Host "=======================================================" -ForegroundColor Cyan
Write-Host " [!] INVESTIGACAO CONCLUIDA COM SUCESSO! " -ForegroundColor Green
Write-Host " O relatorio limpo foi aberto no Bloco de Notas." -ForegroundColor White
Write-Host "=======================================================" -ForegroundColor Cyan
notepad.exe $outputPath
