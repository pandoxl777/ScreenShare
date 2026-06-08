$output = "$env:TEMP\Relatorio_SS_Elite.txt";      
"===================================================" > $output;
"       RELATORIO DE INVESTIGACAO - STAFF FIVEM     " >> $output;
"===================================================" >> $output;
" Desenvolvido por: Jhon" >> $output;
" Data/Hora: $(Get-Date -Format 'dd/MM/yyyy HH:mm:ss')" >> $output;
"===================================================" >> $output;
"" >> $output;
"1. PROCESSOS SUSPEITOS OU ATIVOS" >> $output;
"---------------------------------------------------" >> $output;
$processos = Get-Process | Select-Object Name, Id, @{Name='Path';Expression={$_.Path}}
$processos | Out-String -Width 300 >> $output;
"" >> $output;
"2. CONEXOES DE REDE ATIVAS (IPs E PORTAS)" >> $output;
"---------------------------------------------------" >> $output;
Get-NetTCPConnection -State Established -ErrorAction SilentlyContinue | Select-Object LocalAddress, LocalPort, RemoteAddress, RemotePort, OwningProcess | Out-String -Width 300 >> $output;
"" >> $output;
"3. ARQUIVOS MODIFICADOS NAS ULTIMAS 2 HORAS (TEMP/APPDATA)" >> $output;
"---------------------------------------------------" >> $output;
$arquivosRecentes = Get-ChildItem -Path "$env:TEMP", "$env:APPDATA\CitizenFX" -Recurse -ErrorAction SilentlyContinue | Where-Object { $_.LastWriteTime -gt (Get-Date).AddHours(-2) -and !$_.PSIsContainer }
$arquivosRecentes | Select-Object LastWriteTime, Name, FullName | Out-String -Width 300 >> $output;
"" >> $output;
"4. DIAGNOSTICO AUTOMATICO DE SUSPEITAS" >> $output;
"---------------------------------------------------" >> $output;

# Lista de termos suspeitos comuns em SS de FiveM
$termosSuspeitos = @("cheat", "hack", "injector", "injetor", "bypass", "modmenu", "eulen", "vape", "skript", "trigger", "aimbot", "macro", "recoil")
$suspeitosEncontrados = @()

# 1. Varre os arquivos recentes em busca dos termos
if ($arquivosRecentes) {
    foreach ($arq in $arquivosRecentes) {
        foreach ($termo in $termosSuspeitos) {
            if ($arq.Name -like "*$termo*") {
                $suspeitosEncontrados += "[ALERTA ARQUIVO] Nome suspeito modificado recentemente: $($arq.FullName)"
            }
        }
    }
}

# 2. Varre os processos ativos em busca de termos ou caminhos suspeitos
if ($processos) {
    foreach ($p in $processos) {
        # Verifica se o nome do processo é suspeito
        foreach ($termo in $termosSuspeitos) {
            if ($p.Name -like "*$termo*") {
                $suspeitosEncontrados += "[ALERTA PROCESSO] Processo suspeito ativo: $($p.Name) (ID: $($p.Id))"
            }
        }
        # Verifica se o processo está rodando oculto na Temp ou AppData (comum em cheats disfarçados)
        if ($p.Path -and ($p.Path -like "*$env:TEMP*" -or $p.Path -like "*$env:APPDATA*")) {
            $suspeitosEncontrados += "[ALERTA LOCALIZACAO] Processo rodando de pasta temporaria: $($p.Name) -> Caminho: $($p.Path)"
        }
    }
}

# Escreve o veredito no relatório
if ($suspeitosEncontrados.Count -gt 0) {
    "⚠️ ATENCAO: Foram detectados indicios suspeitos no PC do usuario!" >> $output;
    "---------------------------------------------------" >> $output;
    foreach ($alerta in $suspeitosEncontrados) {
        $alerta >> $output
    }
} else {
    "✅ NENHUM ARQUIVO OU PROCESSO SUSPEITO DETECTADO AUTOMATICAMENTE." >> $output;
    "Nota: Lembre-se de revisar os processos e conexoes manualmente!" >> $output;
}

"" >> $output;
notepad.exe $output
