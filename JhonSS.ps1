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

$outputPath = "$env:LOCALAPPDATA\Temp\Relatorio_SS_Elite.txt"
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
$lines += "Pid      Name                     Path"
$lines += "---      ----                     ----"

$processes = Get-Process -ErrorAction SilentlyContinue | Sort-Object Name
foreach ($p in $processes) {
    $pPath = "Acesso Negado / Protegido"
    try {
        if ($p.MainModule.FileName) { $pPath = $p.MainModule.FileName }
    } catch {}
    
    # Formata a linha como texto simples para evitar objetos complexos no relatório
    $lines += "{0,-8} {1,-24} {2}" -f $p.Id, $p.Name, $pPath
}
$lines += ""

# 2. Conexões de Rede
$lines += "2. CONEXOES DE REDE ATIVAS (IPs E PORTAS)"
$lines += "---------------------------------------------------"
$connections = Get-NetTCPConnection -State Established -ErrorAction SilentlyContinue
foreach ($conn in $connections) {
    $lines += "Processo ID: $($conn.OwningProcess) | Local: $($conn.LocalAddress):$($conn.LocalPort) -> Remoto: $($conn.RemoteAddress):$($conn.RemotePort)"
}
$lines += ""

# 3. Arquivos Modificados (Apenas listagem de TEXTO dos nomes, sem ler o interior deles)
$lines += "3. ARQUIVOS MODIFICADOS NAS ULTIMAS 2 HORAS (TEMP/APPDATA)"
$lines += "---------------------------------------------------"
$twoHoursAgo = (Get-Date).AddHours(-2)
$files = Get-ChildItem -Path "$env:LOCALAPPDATA\Temp", "$env:APPDATA" -File -Recurse -ErrorAction SilentlyContinue | 
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
        # Whitelist do Spotify legítimo para não poluir o relatório
        if ($pPath -notlike "*\AppData\Roaming\Spotify\*") {
            $alerts += "[ALERTA] Processo em pasta temporaria: $($p.Name) -> Caminho: $pPath"
        }
    }
}

if ($alerts.Count -gt 0) {
    $lines += "⚠️ ATENCAO: Foram detectados indicios suspeitos!"
    $lines += "---------------------------------------------------"
    foreach ($alert in $alerts) { $lines += $alert }
} else {
    $lines += "Nenhum indicio grave detectado automaticamente nos caminhos de execucao."
}

# =========================================================================
# SALVAMENTO COMPATÍVEL (Força UTF-8 sem bugs do pipeline do PS 5.1)
# =========================================================================
[System.IO.File]::WriteAllLines($outputPath, $lines, [System.Text.Encoding]::UTF8)

# Mensagem de sucesso e abertura do Bloco de Notas
Write-Host ""
Write-Host "=======================================================" -ForegroundColor Cyan
Write-Host " [!] INVESTIGACAO CONCLUIDA COM SUCESSO! " -ForegroundColor Green
Write-Host " O relatório limpo foi aberto no Bloco de Notas." -ForegroundColor White
Write-Host "=======================================================" -ForegroundColor Cyan
notepad.exe $outputPath
