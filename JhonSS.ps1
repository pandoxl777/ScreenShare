# =========================================================================
# VALIDAÇÃO DE ADMINISTRADOR - Bloqueia a execução se não tiver privilégios
# =========================================================================
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Clear-Host
    Write-Warning "========================================================="
    Write-Warning " ERRO: O script PRECISA ser executado como Administrador!"
    Write-Warning " Por favor, abra o PowerShell como Admin e tente rodar denovo."
    Write-Warning "========================================================="
    Exit
}

# Configuração do caminho do arquivo de saída temporário
$outputPath = "$env:LOCALAPPDATA\Temp\Relatorio_SS_Elite.txt"
$report = New-Object System.Text.StringBuilder

# =========================================================================
# CABEÇALHO DO RELATÓRIO
# =========================================================================
$null = $report.AppendLine("===================================================")
$null = $report.AppendLine("       RELATORIO DE INVESTIGACAO - STAFF FIVEM     ")
$null = $report.AppendLine("===================================================")
$null = $report.AppendLine(" Desenvolvido por: Jhon")
$null = $report.AppendLine(" Data/Hora: $((Get-Date).ToString('dd/MM/yyyy HH:mm:ss'))")
$null = $report.AppendLine("===================================================")
$null = $report.AppendLine("")

# =========================================================================
# 1. PROCESSOS SUSPEITOS OU ATIVOS
# =========================================================================
$null = $report.AppendLine("1. PROCESSOS SUSPEITOS OU ATIVOS")
$null = $report.AppendLine("---------------------------------------------------")
# Puxa o caminho dos processos tratando erros de acessos nativos do Windows
$processes = Get-Process -ErrorAction SilentlyContinue | Select-Object Name, Id, @{Name="Path"; Expression={$_._Path; if(-not $_._Path){$_.MainModule.FileName}}} -ErrorAction SilentlyContinue | Sort-Object Name
$processText = $processes | Out-String
$null = $report.AppendLine($processText)
$null = $report.AppendLine("")

# =========================================================================
# 2. CONEXÕES DE REDE ATIVAS (IPs E PORTAS)
# =========================================================================
$null = $report.AppendLine("2. CONEXOES DE REDE ATIVAS (IPs E PORTAS)")
$null = $report.AppendLine("---------------------------------------------------")
$connections = Get-NetTCPConnection -State Established -ErrorAction SilentlyContinue | Select-Object LocalAddress, LocalPort, RemoteAddress, RemotePort, OwningProcess
foreach ($conn in $connections) {
    $null = $report.AppendLine("LocalAddress  : $($conn.LocalAddress)")
    $null = $report.AppendLine("LocalPort     : $($conn.LocalPort)")
    $null = $report.AppendLine("RemoteAddress : $($conn.RemoteAddress)")
    $null = $report.AppendLine("RemotePort    : $($conn.RemotePort)")
    $null = $report.AppendLine("OwningProcess : $($conn.OwningProcess)")
    $null = $report.AppendLine("")
}
$null = $report.AppendLine("")

# =========================================================================
# 3. ARQUIVOS MODIFICADOS NAS ÚLTIMAS 2 HORAS
# =========================================================================
$null = $report.AppendLine("3. ARQUIVOS MODIFICADOS NAS ULTIMAS 2 HORAS (TEMP/APPDATA)")
$null = $report.AppendLine("---------------------------------------------------")
$twoHoursAgo = (Get-Date).AddHours(-2)
$files = Get-ChildItem -Path "$env:LOCALAPPDATA\Temp", "$env:APPDATA" -File -Recurse -ErrorAction SilentlyContinue | 
         Where-Object { $_.LastWriteTime -gt $twoHoursAgo } | 
         Select-Object LastWriteTime, Name, FullName | Sort-Object LastWriteTime
$filesText = $files | Out-String
$null = $report.AppendLine($filesText)
$null = $report.AppendLine("")

# =========================================================================
# 4. DIAGNÓSTICO AUTOMÁTICO DE SUSPEITAS (Com Whitelist do Spotify)
# =========================================================================
$null = $report.AppendLine("4. DIAGNOSTICO AUTOMATICO DE SUSPEITAS")
$null = $report.AppendLine("---------------------------------------------------")

$alerts = @()
foreach ($p in $processes) {
    if ($p.Path) {
        # Alerta se rodar da AppData ou Temp, mas IGNORA se for o Spotify legítimo
        if (($p.Path -like "*\AppData\*" -or $p.Path -like "*\Temp\*") -and ($p.Path -notlike "*\AppData\Roaming\Spotify\*")) {
            $alerts += "[ALERTA LOCALIZACAO] Processo rodando de pasta temporaria: $($p.Name) -> Caminho: $($p.Path)"
        }
    }
}

if ($alerts.Count -gt 0) {
    $null = $report.AppendLine("⚠️ ATENCAO: Foram detectados indicios suspeitos no PC do usuario!")
    $null = $report.AppendLine("---------------------------------------------------")
    foreach ($alert in $alerts) {
        $null = $report.AppendLine($alert)
    }
} else {
    $null = $report.AppendLine("Nenhum indicio grave detectado automaticamente nos caminhos de execucao.")
}

# =========================================================================
# SALVAMENTO E FINALIZAÇÃO
# =========================================================================
$report.ToString() | Out-File -FilePath $outputPath -Encoding utf8

# Exibe confirmação no terminal do Staff e abre o bloco de notas automaticamente
Write-Host ""
Write-Host "=======================================================" -ForegroundColor Cyan
Write-Host " [!] INVESTIGACAO CONCLUIDA COM SUCESSO! " -ForegroundColor Green
Write-Host " O relatório completo foi aberto no Bloco de Notas." -ForegroundColor White
Write-Host "=======================================================" -ForegroundColor Cyan
notepad.exe $outputPath
