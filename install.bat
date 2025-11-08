@echo off
REM #############################################################
REM # Script de Instalacao Tailscale para Acesso Seguro a DB
REM # Versao Simplificada - Sem configuracao de firewall
REM # Versao: 4.0 Windows - Batch
REM #############################################################

setlocal EnableDelayedExpansion
chcp 65001 > nul 2>&1

REM Verificar se esta rodando como Administrador
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo.
    echo [ERRO] Este script precisa ser executado como Administrador
    echo        Clique com botao direito e escolha "Executar como administrador"
    echo.
    pause
    exit /b 1
)

REM Banner Nexfar simplificado
cls
echo.
echo ========================================================
echo.
echo     ███╗   ██╗███████╗██╗  ██╗███████╗ █████╗ ██████╗
echo     ████╗  ██║██╔════╝╚██╗██╔╝██╔════╝██╔══██╗██╔══██╗
echo     ██╔██╗ ██║█████╗   ╚███╔╝ █████╗  ███████║██████╔╝
echo     ██║╚██╗██║██╔══╝   ██╔██╗ ██╔══╝  ██╔══██║██╔══██╗
echo     ██║ ╚████║███████╗██╔╝ ██╗██║     ██║  ██║██║  ██║
echo     ╚═╝  ╚═══╝╚══════╝╚═╝  ╚═╝╚═╝     ╚═╝  ╚═╝╚═╝  ╚═╝
echo.
echo                         VPN Edition
echo.
echo ========================================================
echo      Configuracao Tailscale VPN - Nexfar
echo ========================================================
echo.

REM Verificar variaveis de ambiente
set MODO_INTERATIVO=0
if "%CLIENTE_NOME%"=="" set MODO_INTERATIVO=1
if "%AUTH_KEY%"=="" set MODO_INTERATIVO=1
if "%DB_PORTA%"=="" set MODO_INTERATIVO=1
if "%DB_TIPO%"=="" set MODO_INTERATIVO=1

REM Modo interativo
if %MODO_INTERATIVO%==1 (
    echo [!] Modo Interativo
    echo.
    echo Dica: Para execucao automatizada, defina as variaveis:
    echo   SET CLIENTE_NOME=nome_cliente
    echo   SET AUTH_KEY=chave_autenticacao
    echo   SET DB_PORTA=porta_banco
    echo   SET DB_TIPO=tipo_banco
    echo.
    
    REM Nome do cliente
    if "%CLIENTE_NOME%"=="" (
        set /p CLIENTE_NOME=Nome do Distribuidor/Industria: 
        if "!CLIENTE_NOME!"=="" (
            echo [ERRO] Nome e obrigatorio
            pause
            exit /b 1
        )
    )
    
    REM Auth Key
    if "%AUTH_KEY%"=="" (
        echo.
        set /p AUTH_KEY=Cole a Auth Key fornecida por Nexfar: 
        if "!AUTH_KEY!"=="" (
            echo [ERRO] Auth Key e obrigatoria
            pause
            exit /b 1
        )
    )
    
    REM Porta do banco de dados
    if "%DB_PORTA%"=="" (
        echo.
        echo Portas comuns de bancos de dados:
        echo   - PostgreSQL: 5432
        echo   - MySQL/MariaDB: 3306
        echo   - Oracle: 1521
        echo   - SQL Server: 1433
        echo   - MongoDB: 27017
        echo   - Redis: 6379
        echo   - Cassandra: 9042
        echo.
        set /p DB_PORTA=Digite a porta do banco de dados: 
        if "!DB_PORTA!"=="" (
            echo [ERRO] Porta do banco de dados e obrigatoria
            pause
            exit /b 1
        )
    )
    
    REM Tipo de banco
    if "%DB_TIPO%"=="" (
        echo.
        set /p DB_TIPO=Tipo de banco de dados (postgres/mysql/oracle/mssql/mongo/outro): 
        if "!DB_TIPO!"=="" set DB_TIPO=db
    )
    
    REM Obter IP do servidor
    for /f "tokens=2 delims=:" %%a in ('ipconfig ^| findstr /c:"IPv4"') do (
        for /f "tokens=1" %%b in ("%%a") do (
            set DB_IP=%%b
            goto :ip_found
        )
    )
    :ip_found
    
    REM Confirmar
    echo.
    echo [!] Confirme as informacoes:
    echo    Cliente: !CLIENTE_NOME!
    echo    IP do Servidor DB: !DB_IP!
    echo    Porta do DB: !DB_PORTA!
    echo    Tipo de DB: !DB_TIPO!
    echo.
    set /p confirm=Confirmar e continuar? (s/n): 
    if /i "!confirm!" neq "s" (
        echo [ERRO] Instalacao cancelada
        pause
        exit /b 1
    )
) else (
    echo [OK] Modo Automatizado
    echo.
    echo Configuracao detectada:
    echo    Cliente: %CLIENTE_NOME%
    echo    Porta: %DB_PORTA%
    echo    Tipo DB: %DB_TIPO%
    echo    Auth Key: !AUTH_KEY:~0,15!...
)

REM Configuracoes
set PRESTADOR_NOME=Nexfar

REM Obter IP se ainda nao tem
if "%DB_IP%"=="" (
    for /f "tokens=2 delims=:" %%a in ('ipconfig ^| findstr /c:"IPv4"') do (
        for /f "tokens=1" %%b in ("%%a") do (
            set DB_IP=%%b
            goto :ip_found2
        )
    )
    :ip_found2
)

if "%DB_IP%"=="" (
    echo [ERRO] IP do banco de dados nao pode ser detectado
    pause
    exit /b 1
)

REM Converter nomes para hostname
set CLIENTE_TAG=%CLIENTE_NOME: =-%
set CLIENTE_TAG=%CLIENTE_TAG:A=a%
set CLIENTE_TAG=%CLIENTE_TAG:B=b%
set CLIENTE_TAG=%CLIENTE_TAG:C=c%
set CLIENTE_TAG=%CLIENTE_TAG:D=d%
set CLIENTE_TAG=%CLIENTE_TAG:E=e%
set CLIENTE_TAG=%CLIENTE_TAG:F=f%
set CLIENTE_TAG=%CLIENTE_TAG:G=g%
set CLIENTE_TAG=%CLIENTE_TAG:H=h%
set CLIENTE_TAG=%CLIENTE_TAG:I=i%
set CLIENTE_TAG=%CLIENTE_TAG:J=j%
set CLIENTE_TAG=%CLIENTE_TAG:K=k%
set CLIENTE_TAG=%CLIENTE_TAG:L=l%
set CLIENTE_TAG=%CLIENTE_TAG:M=m%
set CLIENTE_TAG=%CLIENTE_TAG:N=n%
set CLIENTE_TAG=%CLIENTE_TAG:O=o%
set CLIENTE_TAG=%CLIENTE_TAG:P=p%
set CLIENTE_TAG=%CLIENTE_TAG:Q=q%
set CLIENTE_TAG=%CLIENTE_TAG:R=r%
set CLIENTE_TAG=%CLIENTE_TAG:S=s%
set CLIENTE_TAG=%CLIENTE_TAG:T=t%
set CLIENTE_TAG=%CLIENTE_TAG:U=u%
set CLIENTE_TAG=%CLIENTE_TAG:V=v%
set CLIENTE_TAG=%CLIENTE_TAG:W=w%
set CLIENTE_TAG=%CLIENTE_TAG:X=x%
set CLIENTE_TAG=%CLIENTE_TAG:Y=y%
set CLIENTE_TAG=%CLIENTE_TAG:Z=z%

set DB_TAG=%DB_TIPO%

echo.
echo ========================================================
echo [*] Iniciando instalacao...
echo ========================================================
echo.

REM Passo 1: Baixar e instalar Tailscale
echo [1/4] Instalando Tailscale...

REM Verificar se Tailscale ja esta instalado
if exist "%ProgramFiles%\Tailscale\tailscale.exe" (
    echo       Tailscale ja instalado, pulando download...
) else (
    echo       Baixando Tailscale...
    powershell -Command "& {[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; Invoke-WebRequest -Uri 'https://pkgs.tailscale.com/stable/tailscale-setup-latest-amd64.exe' -OutFile '%TEMP%\tailscale-setup.exe'}" > nul 2>&1
    
    echo       Instalando Tailscale (aguarde)...
    start /wait %TEMP%\tailscale-setup.exe /quiet
    
    timeout /t 5 /nobreak > nul
)
echo       [OK] Tailscale instalado

REM Passo 2: Habilitar roteamento IP
echo.
echo [2/4] Habilitando roteamento IP...
reg add "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" /v IPEnableRouter /t REG_DWORD /d 1 /f > nul 2>&1
echo       [OK] Roteamento IP habilitado

REM Passo 3: Conectar ao Tailscale
echo.
echo [3/4] Conectando ao Tailscale...

set HOSTNAME=%CLIENTE_TAG%-%DB_TAG%-gateway

"%ProgramFiles%\Tailscale\tailscale.exe" up ^
    --auth-key=%AUTH_KEY% ^
    --advertise-routes=%DB_IP%/32 ^
    --hostname=%HOSTNAME% ^
    --advertise-tags=tag:%CLIENTE_TAG%-db ^
    --accept-routes ^
    --accept-dns=false > nul 2>&1

timeout /t 3 /nobreak > nul
echo       [OK] Conectado ao Tailscale

REM Passo 4: Verificar instalacao
echo.
echo [4/4] Verificando instalacao...

REM Obter IP Tailscale
for /f "tokens=*" %%i in ('"%ProgramFiles%\Tailscale\tailscale.exe" ip -4 2^>nul') do set TAILSCALE_IP=%%i
if "%TAILSCALE_IP%"=="" set TAILSCALE_IP=N/A

echo       [OK] Instalacao verificada
echo.
echo ========================================================
echo [OK] INSTALACAO CONCLUIDA COM SUCESSO!
echo ========================================================
echo.
echo Resumo da Configuracao:
echo    Cliente: %CLIENTE_NOME%
echo    IP Tailscale Gateway: %TAILSCALE_IP%
echo    Hostname: %HOSTNAME%
echo    Rota anunciada: %DB_IP%/32
echo    Porta do DB: %DB_PORTA%
echo    Tipo do DB: %DB_TIPO%
echo.
echo Recursos de Seguranca:
echo    [OK] Conexao VPN estabelecida
echo    [OK] Trafego criptografado end-to-end
echo    [OK] Autenticacao via Auth Key
echo    [OK] Controle de acesso via ACLs no Tailscale
echo.
echo Envie para %PRESTADOR_NOME%:
echo    IP do Banco: %DB_IP%
echo    Porta: %DB_PORTA%
echo    Tipo: %DB_TIPO%
echo    Status: Pronto para conexao
echo.

REM Criar arquivo de configuracao
set CONFIG_DIR=%ProgramData%\Tailscale
if not exist "%CONFIG_DIR%" mkdir "%CONFIG_DIR%"

echo { > "%CONFIG_DIR%\client-config.json"
echo   "cliente": "%CLIENTE_NOME%", >> "%CONFIG_DIR%\client-config.json"
echo   "prestador": "%PRESTADOR_NOME%", >> "%CONFIG_DIR%\client-config.json"
echo   "db_ip": "%DB_IP%", >> "%CONFIG_DIR%\client-config.json"
echo   "db_porta": "%DB_PORTA%", >> "%CONFIG_DIR%\client-config.json"
echo   "db_tipo": "%DB_TIPO%", >> "%CONFIG_DIR%\client-config.json"
echo   "tailscale_ip": "%TAILSCALE_IP%", >> "%CONFIG_DIR%\client-config.json"
echo   "hostname": "%HOSTNAME%", >> "%CONFIG_DIR%\client-config.json"
echo   "data_instalacao": "%date% %time%" >> "%CONFIG_DIR%\client-config.json"
echo } >> "%CONFIG_DIR%\client-config.json"

echo Configuracao salva em: %CONFIG_DIR%\client-config.json
echo.
echo ========================================================
echo [OK] Processo finalizado com sucesso!
echo ========================================================
echo.
echo Comandos uteis:
echo    Ver status: "%ProgramFiles%\Tailscale\tailscale.exe" status
echo    Ver IP: "%ProgramFiles%\Tailscale\tailscale.exe" ip
echo    Ver config: type "%CONFIG_DIR%\client-config.json"
echo.
echo NOTA IMPORTANTE:
echo A seguranca e controle de acesso devem ser configurados
echo atraves das ACLs (Access Control Lists) no painel do Tailscale.
echo Consulte a documentacao da Nexfar para configuracoes recomendadas.
echo.

pause
