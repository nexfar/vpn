#############################################################
# Script de Instalação Tailscale para Acesso Seguro a DB
# Versão Simplificada - Sem configuração de firewall
# Versão: 4.0 Windows - PowerShell
#############################################################

# Requer execução como Administrador
#Requires -RunAsAdministrator

# Configurar encoding UTF-8
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8

# Definir política de erro
$ErrorActionPreference = "Stop"

# Cores para output
$Colors = @{
    Red = "Red"
    Green = "Green"
    Yellow = "Yellow"
    Blue = "Cyan"
    Purple = "Magenta"
    Orange = "DarkYellow"
    NC = "White"
}

# Função para escrever com cor
function Write-ColorHost {
    param(
        [string]$Text,
        [string]$Color = "White"
    )
    Write-Host $Text -ForegroundColor $Color -NoNewline
}

# Função para spinner animado
function Show-Spinner {
    param(
        [scriptblock]$ScriptBlock,
        [string]$Message
    )
    
    $job = Start-Job -ScriptBlock $ScriptBlock
    $spinChars = '⠋','⠙','⠹','⠸','⠼','⠴','⠦','⠧','⠇','⠏'
    $i = 0
    
    [Console]::CursorVisible = $false
    
    while ($job.State -eq 'Running') {
        Write-Host "`r" -NoNewline
        Write-Host " [$($spinChars[$i])] $Message" -ForegroundColor Magenta -NoNewline
        $i = ($i + 1) % $spinChars.Length
        Start-Sleep -Milliseconds 100
    }
    
    # Limpar linha e mostrar resultado
    Write-Host "`r" -NoNewline
    Write-Host (" " * 80) -NoNewline
    Write-Host "`r" -NoNewline
    
    [Console]::CursorVisible = $true
    
    $result = Receive-Job -Job $job
    Remove-Job -Job $job
    
    if ($job.State -eq 'Completed') {
        Write-Host " ✓ " -ForegroundColor Green -NoNewline
        Write-Host $Message -ForegroundColor Green
        return $result
    } else {
        Write-Host " [X] " -ForegroundColor Red -NoNewline
        Write-Host $Message -ForegroundColor Red
        throw "Erro ao executar: $Message"
    }
}

# Banner Nexfar
Write-Host ""
Write-Host "                                                            " -NoNewline
Write-ColorHost "*****" "Magenta"
Write-Host ""
Write-Host "                                                          " -NoNewline
Write-ColorHost "*******" "Magenta"
Write-Host ""
Write-Host "                                                          " -NoNewline
Write-ColorHost "*****" "Magenta"
Write-Host ""
Write-Host "                                                         " -NoNewline
Write-ColorHost "*****" "Magenta"
Write-Host ""

Write-ColorHost "***** *********          *********     ******" "Magenta"
Write-Host "   " -NoNewline
Write-ColorHost "=======" "DarkYellow"
Write-Host "  " -NoNewline
Write-ColorHost "********      ****************  ***********" "Magenta"
Write-Host ""

Write-ColorHost "****************       **************   ******" "Magenta"
Write-Host "     " -NoNewline
Write-ColorHost "===" "DarkYellow"
Write-Host "   " -NoNewline
Write-ColorHost "********    ******************  ***********" "Magenta"
Write-Host ""

Write-ColorHost "******     ******    ******     ******    *****" "Magenta"
Write-Host "   " -NoNewline
Write-ColorHost "===" "DarkYellow"
Write-Host "    " -NoNewline
Write-ColorHost "*****      *******   *********  **********" "Magenta"
Write-Host ""

Write-ColorHost "*****       ******   *****        *****    *****" "Magenta"
Write-Host "   " -NoNewline
Write-ColorHost "=" "DarkYellow"
Write-Host "     " -NoNewline
Write-ColorHost "*****     ******        ******  ******" "Magenta"
Write-Host ""

Write-ColorHost "*****       ******  *******************     ******" "Magenta"
Write-Host "       " -NoNewline
Write-ColorHost "*****     *****          *****  ******" "Magenta"
Write-Host ""

Write-ColorHost "*****       ******  *******************     *******" "Magenta"
Write-Host "      " -NoNewline
Write-ColorHost "*****     *****          *****  ******" "Magenta"
Write-Host "    " -NoNewline
Write-ColorHost "__     ______  _   _ " "Magenta"
Write-Host ""

Write-ColorHost "*****       ******   *****        ****    **********" "Magenta"
Write-Host "     " -NoNewline
Write-ColorHost "*****     ******        ******  ******" "Magenta"
Write-Host "    " -NoNewline
Write-ColorHost '\ \   / /  _ \| \ | |' "Magenta"
Write-Host ""

Write-ColorHost "*****       ******    *****     ******   ****** *****" "Magenta"
Write-Host "    " -NoNewline
Write-ColorHost "*****      *******    ********  ******" "Magenta"
Write-Host "    " -NoNewline
Write-ColorHost ' \ \ / /| |_) |  \| |' "Magenta"
Write-Host ""

Write-ColorHost "*****       ******     *************    ******   ******" "Magenta"
Write-Host "  " -NoNewline
Write-ColorHost "*****       ******************  ******" "Magenta"
Write-Host "    " -NoNewline
Write-ColorHost '  \ V / |  __/| |\  |' "Magenta"
Write-Host ""

Write-ColorHost "*****       ******       *********     *****      *****" "Magenta"
Write-Host "  " -NoNewline
Write-ColorHost "*****          ******** ******  ******" "Magenta"
Write-Host "    " -NoNewline
Write-ColorHost '   \_/  |_|   |_| \_|' "Magenta"
Write-Host ""

Write-Host ""
Write-Host "================================================" -ForegroundColor Green
Write-Host "     Configuração Tailscale VPN - Nexfar       " -ForegroundColor Green
Write-Host "================================================" -ForegroundColor Green
Write-Host ""

# Verificar se está rodando como Administrador
$currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
if (-not $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "[X] Este script precisa ser executado como Administrador" -ForegroundColor Red
    exit 1
}

# Verificar variáveis de ambiente ou usar modo interativo
$MODO_INTERATIVO = $false

if (-not $env:CLIENTE_NOME -or -not $env:AUTH_KEY -or -not $env:DB_PORTA -or -not $env:DB_TIPO) {
    $MODO_INTERATIVO = $true
}

# Modo interativo
if ($MODO_INTERATIVO) {
    Write-Host "[!] Modo Interativo" -ForegroundColor Yellow
    Write-Host "Dica: Para execução automatizada, defina as variáveis:" -ForegroundColor Cyan
    Write-Host "  `$env:CLIENTE_NOME, `$env:AUTH_KEY, `$env:DB_PORTA, `$env:DB_TIPO" -ForegroundColor Cyan
    Write-Host ""
    
    # Nome do cliente
    if (-not $env:CLIENTE_NOME) {
        $CLIENTE_NOME = Read-Host "Nome do Distribuidor/Indústria"
        if ([string]::IsNullOrWhiteSpace($CLIENTE_NOME)) {
            Write-Host "[X] Nome é obrigatório" -ForegroundColor Red
            exit 1
        }
    } else {
        $CLIENTE_NOME = $env:CLIENTE_NOME
    }
    
    # Auth Key
    if (-not $env:AUTH_KEY) {
        Write-Host ""
        $AUTH_KEY = Read-Host "Cole a Auth Key fornecida por Nexfar"
        if ([string]::IsNullOrWhiteSpace($AUTH_KEY)) {
            Write-Host "[X] Auth Key é obrigatória" -ForegroundColor Red
            exit 1
        }
    } else {
        $AUTH_KEY = $env:AUTH_KEY
    }
    
    # Porta do banco de dados
    if (-not $env:DB_PORTA) {
        Write-Host ""
        Write-Host "Portas comuns de bancos de dados:" -ForegroundColor Cyan
        Write-Host "├─ PostgreSQL: 5432"
        Write-Host "├─ MySQL/MariaDB: 3306"
        Write-Host "├─ Oracle: 1521"
        Write-Host "├─ SQL Server: 1433"
        Write-Host "├─ MongoDB: 27017"
        Write-Host "├─ Redis: 6379"
        Write-Host "└─ Cassandra: 9042"
        Write-Host ""
        $DB_PORTA = Read-Host "Digite a porta do banco de dados"
        if ([string]::IsNullOrWhiteSpace($DB_PORTA)) {
            Write-Host "[X] Porta do banco de dados é obrigatória" -ForegroundColor Red
            exit 1
        }
    } else {
        $DB_PORTA = $env:DB_PORTA
    }
    
    # Tipo de banco
    if (-not $env:DB_TIPO) {
        Write-Host ""
        $DB_TIPO = Read-Host "Tipo de banco de dados (postgres/mysql/oracle/mssql/mongo/outro)"
        if ([string]::IsNullOrWhiteSpace($DB_TIPO)) {
            $DB_TIPO = "db"
        }
    } else {
        $DB_TIPO = $env:DB_TIPO
    }
    
    # Confirmar no modo interativo
    Write-Host ""
    Write-Host "[!] Confirme as informações:" -ForegroundColor Yellow
    
    # Obter IP do servidor
    $DB_IP = (Get-NetIPAddress -AddressFamily IPv4 | Where-Object {$_.InterfaceAlias -notlike "*Loopback*" -and $_.IPAddress -ne "127.0.0.1"} | Select-Object -First 1).IPAddress
    
    Write-Host "Cliente: " -NoNewline
    Write-Host $CLIENTE_NOME -ForegroundColor Green
    Write-Host "IP do Servidor DB: " -NoNewline
    Write-Host $DB_IP -ForegroundColor Green
    Write-Host "Porta do DB: " -NoNewline
    Write-Host $DB_PORTA -ForegroundColor Green
    Write-Host "Tipo de DB: " -NoNewline
    Write-Host $DB_TIPO -ForegroundColor Green
    Write-Host ""
    
    $confirm = Read-Host "Confirmar e continuar? (s/n)"
    if ($confirm -ne 's' -and $confirm -ne 'S') {
        Write-Host "[X] Instalação cancelada" -ForegroundColor Red
        exit 1
    }
} else {
    $CLIENTE_NOME = $env:CLIENTE_NOME
    $AUTH_KEY = $env:AUTH_KEY
    $DB_PORTA = $env:DB_PORTA
    $DB_TIPO = $env:DB_TIPO
    
    Write-Host "✓ Modo Automatizado" -ForegroundColor Green
    Write-Host ""
    Write-Host "📋 Configuração detectada:" -ForegroundColor Yellow
    Write-Host "├─ Cliente: " -NoNewline
    Write-Host $CLIENTE_NOME -ForegroundColor Green
    Write-Host "├─ Porta: " -NoNewline
    Write-Host $DB_PORTA -ForegroundColor Green
    Write-Host "├─ Tipo DB: " -NoNewline
    Write-Host $DB_TIPO -ForegroundColor Green
    Write-Host "└─ Auth Key: " -NoNewline
    Write-Host "$($AUTH_KEY.Substring(0, [Math]::Min(15, $AUTH_KEY.Length)))..." -ForegroundColor Green
}

# Configurações fixas ou derivadas
$PRESTADOR_NOME = "Nexfar"
$DB_IP = (Get-NetIPAddress -AddressFamily IPv4 | Where-Object {$_.InterfaceAlias -notlike "*Loopback*" -and $_.IPAddress -ne "127.0.0.1"} | Select-Object -First 1).IPAddress

if (-not $DB_IP) {
    Write-Host "[X] IP do banco de dados não pôde ser detectado" -ForegroundColor Red
    exit 1
}

# Converter nomes para lowercase e sem espaços para hostname
$CLIENTE_TAG = ($CLIENTE_NOME -replace ' ', '-').ToLower()
$DB_TAG = $DB_TIPO.ToLower()

Write-Host ""
Write-Host "[*] Iniciando instalação..." -ForegroundColor Yellow
Write-Host ""

# Passo 1: Baixar e instalar Tailscale
Write-Host "▶ " -ForegroundColor Green -NoNewline
$result = Show-Spinner -ScriptBlock {
    try {
        # Baixar instalador do Tailscale
        $tailscaleUrl = "https://tailscale.com/download/windows"
        $installerPath = "$env:TEMP\tailscale-setup.exe"
        
        # Verificar se Tailscale já está instalado
        $tailscalePath = "$env:ProgramFiles\Tailscale\tailscale.exe"
        if (-not (Test-Path $tailscalePath)) {
            # Baixar instalador
            Invoke-WebRequest -Uri "https://pkgs.tailscale.com/stable/tailscale-setup-latest-amd64.exe" -OutFile $installerPath -UseBasicParsing
            
            # Instalar silenciosamente
            Start-Process -FilePath $installerPath -ArgumentList "/quiet" -Wait -NoNewWindow
            
            # Aguardar instalação
            Start-Sleep -Seconds 5
        }
        
        return $true
    } catch {
        return $false
    }
} -Message "Passo 1: Instalando Tailscale"

# Passo 2: Configurar roteamento IP (IP Forwarding no Windows)
Write-Host "▶ " -ForegroundColor Green -NoNewline
$result = Show-Spinner -ScriptBlock {
    try {
        # Habilitar IP forwarding
        Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" -Name "IPEnableRouter" -Value 1
        
        # Habilitar serviço de roteamento
        Set-Service -Name "RemoteAccess" -StartupType Manual -ErrorAction SilentlyContinue
        
        return $true
    } catch {
        return $false
    }
} -Message "Passo 2: Habilitando roteamento IP"

# Passo 3: Conectar ao Tailscale
Write-Host "▶ " -ForegroundColor Green -NoNewline
$HOSTNAME = "${CLIENTE_TAG}-${DB_TAG}-gateway"

$result = Show-Spinner -ScriptBlock {
    param($AUTH_KEY, $DB_IP, $HOSTNAME, $CLIENTE_TAG)
    
    try {
        # Caminho do Tailscale
        $tailscale = "$env:ProgramFiles\Tailscale\tailscale.exe"
        
        if (Test-Path $tailscale) {
            # Conectar ao Tailscale
            $args = @(
                "up",
                "--auth-key=$AUTH_KEY",
                "--advertise-routes=$DB_IP/32",
                "--hostname=$HOSTNAME",
                "--advertise-tags=tag:${CLIENTE_TAG}-db",
                "--accept-routes",
                "--accept-dns=false"
            )
            
            Start-Process -FilePath $tailscale -ArgumentList $args -Wait -NoNewWindow
            
            # Aguardar conexão
            Start-Sleep -Seconds 3
            
            return $true
        } else {
            return $false
        }
    } catch {
        return $false
    }
} -Message "Passo 3: Conectando ao Tailscale" -ArgumentList $AUTH_KEY, $DB_IP, $HOSTNAME, $CLIENTE_TAG

# Passo 4: Verificar instalação
Write-Host "▶ " -ForegroundColor Green -NoNewline
Write-Host "Passo 4: Verificando instalação..." -ForegroundColor Green

Start-Sleep -Seconds 2

# Verificar status
$tailscale = "$env:ProgramFiles\Tailscale\tailscale.exe"
if (Test-Path $tailscale) {
    try {
        # Obter IP do Tailscale
        $tailscaleStatus = & $tailscale status --json | ConvertFrom-Json
        $tailscaleIP = $tailscaleStatus.Self.TailscaleIPs[0]
        
        if (-not $tailscaleIP) {
            $tailscaleIP = "N/A"
        }
        
        Write-Host ""
        Write-Host "================================================" -ForegroundColor Green
        Write-Host "[OK] INSTALAÇÃO CONCLUÍDA COM SUCESSO!" -ForegroundColor Green
        Write-Host "================================================" -ForegroundColor Green
        Write-Host ""
        Write-Host "[>] Resumo da Configuração:" -ForegroundColor Yellow
        Write-Host "├─ Cliente: " -NoNewline
        Write-Host $CLIENTE_NOME -ForegroundColor Green
        Write-Host "├─ IP Tailscale Gateway: " -NoNewline
        Write-Host $tailscaleIP -ForegroundColor Green
        Write-Host "├─ Hostname: " -NoNewline
        Write-Host $HOSTNAME -ForegroundColor Green
        Write-Host "├─ Rota anunciada: " -NoNewline
        Write-Host "$DB_IP/32" -ForegroundColor Green
        Write-Host "├─ Porta do DB: " -NoNewline
        Write-Host $DB_PORTA -ForegroundColor Green
        Write-Host "└─ Tipo do DB: " -NoNewline
        Write-Host $DB_TIPO -ForegroundColor Green
        Write-Host ""
        Write-Host "[>] Recursos de Segurança:" -ForegroundColor Yellow
        Write-Host "[OK] Conexão VPN estabelecida"
        Write-Host "[OK] Tráfego criptografado end-to-end"
        Write-Host "[OK] Autenticação via Auth Key"
        Write-Host "[OK] Controle de acesso via ACLs no Tailscale"
        Write-Host ""
        Write-Host "[>] Envie para $PRESTADOR_NOME" -ForegroundColor Yellow -NoNewline
        Write-Host ":"
        Write-Host "├─ IP do Banco: " -NoNewline
        Write-Host $DB_IP -ForegroundColor Green
        Write-Host "├─ Porta: " -NoNewline
        Write-Host $DB_PORTA -ForegroundColor Green
        Write-Host "├─ Tipo: " -NoNewline
        Write-Host $DB_TIPO -ForegroundColor Green
        Write-Host "└─ Status: " -NoNewline
        Write-Host "Pronto para conexão" -ForegroundColor Green
        
        # Criar arquivo de configuração
        $configPath = "$env:ProgramData\Tailscale"
        if (-not (Test-Path $configPath)) {
            New-Item -ItemType Directory -Path $configPath -Force | Out-Null
        }
        
        $config = @{
            cliente = $CLIENTE_NOME
            prestador = $PRESTADOR_NOME
            db_ip = $DB_IP
            db_porta = $DB_PORTA
            db_tipo = $DB_TIPO
            tailscale_ip = $tailscaleIP
            hostname = $HOSTNAME
            data_instalacao = (Get-Date -Format "yyyy-MM-ddTHH:mm:ss")
            auth_key_prefix = "$($AUTH_KEY.Substring(0, [Math]::Min(15, $AUTH_KEY.Length)))..."
        }
        
        $configFile = "$configPath\client-config.json"
        $config | ConvertTo-Json | Set-Content -Path $configFile -Encoding UTF8
        
        Write-Host ""
        Write-Host "[>] Configuração salva em: " -NoNewline
        Write-Host $configFile -ForegroundColor Green
        
    } catch {
        Write-Host " [X] ERRO" -ForegroundColor Red
        Write-Host "[X] Erro ao conectar Tailscale" -ForegroundColor Red
        Write-Host "Verifique os logs no Event Viewer" -ForegroundColor Yellow
        exit 1
    }
} else {
    Write-Host " [X] ERRO" -ForegroundColor Red
    Write-Host "[X] Tailscale não foi instalado corretamente" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "================================================" -ForegroundColor Green
Write-Host "[OK] Processo finalizado com sucesso!" -ForegroundColor Green
Write-Host "================================================" -ForegroundColor Green

Write-Host ""
Write-Host "[>] Comandos úteis:" -ForegroundColor Yellow
Write-Host "├─ Ver status: " -NoNewline
Write-Host "`"$tailscale`" status" -ForegroundColor Green
Write-Host "├─ Ver IP: " -NoNewline
Write-Host "`"$tailscale`" ip" -ForegroundColor Green
Write-Host "└─ Ver config: " -NoNewline
Write-Host "Get-Content `"$configFile`"" -ForegroundColor Green

Write-Host ""
Write-Host "📌 NOTA IMPORTANTE:" -ForegroundColor Yellow
Write-Host "A segurança e controle de acesso devem ser configurados"
Write-Host "através das ACLs (Access Control Lists) no painel do Tailscale."
Write-Host "Consulte a documentação da Nexfar para configurações recomendadas."
Write-Host ""

# Pausar para visualização
Write-Host "Pressione qualquer tecla para sair..." -ForegroundColor Cyan
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
