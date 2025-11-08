#!/bin/bash
#############################################################
# Script de Instalação Tailscale para Acesso Seguro a DB
# Versão Simplificada - Sem configuração de firewall
# Versão: 4.0
#############################################################

set -e  # Parar se houver erro

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color
PURPLE='\e[38;5;93m'
ORANGE='\e[38;5;208m'

# Função para spinner animado
spinner() {
    local pid=$1
    local message=$2
    local delay=0.1
    local spinstr='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'
    
    tput civis 2>/dev/null || true
    
    while [ "$(ps a 2>/dev/null | awk '{print $1}' | grep $pid)" ]; do
        local temp=${spinstr#?}
        printf "\033[2K\r${PURPLE}${NC} [%s] %s${NC}" "${spinstr:0:1}" "$message"
        local spinstr=$temp${spinstr%"$temp"}
        sleep $delay
    done
    
    printf "\033[2K\r ${GREEN}✓${NC}  "
    
    tput cnorm 2>/dev/null || true
}

# Função para executar comando com spinner
run_with_spinner() {
    local message=$1
    shift
    
    echo -ne "${PURPLE}▶${NC} $message..."
    
    # Executar comando em background
    "$@" > /dev/null 2>&1 &
    local cmd_pid=$!
    
    # Mostrar spinner
    spinner $cmd_pid "$message"
    
    # Esperar comando terminar
    wait $cmd_pid
    local return_code=$?
    
    if [ $return_code -eq 0 ]; then
        echo -e " ${GREEN}${message}${NC}"
    else
        echo -e " ${RED}ERRO${NC}"
        return $return_code
    fi
}

echo # Add a blank line for top padding

printf "                                                            ${PURPLE}*****${NC}\n"
printf "                                                          ${PURPLE}*******${NC}\n"
printf "                                                          ${PURPLE}*****${NC}\n"
printf "                                                         ${PURPLE}*****${NC}\n"
printf "${PURPLE}***** *********          *********     ******${NC}   ${ORANGE}=======${NC}  ${PURPLE}********      ****************  ***********${NC}\n"
printf "${PURPLE}****************       **************   ******${NC}     ${ORANGE}===${NC}   ${PURPLE}********    ******************  ***********${NC}\n"
printf "${PURPLE}******     ******    ******     ******    *****${NC}   ${ORANGE}===${NC}    ${PURPLE}*****      *******   *********  **********${NC}\n"
printf "${PURPLE}*****       ******   *****        *****    *****${NC}   ${ORANGE}=${NC}     ${PURPLE}*****     ******        ******  ******${NC}\n"
printf "${PURPLE}*****       ******  *******************     ******${NC}       ${PURPLE}*****     *****          *****  ******${NC}\n"
printf "${PURPLE}*****       ******  *******************     *******${NC}      ${PURPLE}*****     *****          *****  ******${NC}    ${PURPLE}__     ______  _   _ ${NC}\n"
printf "${PURPLE}*****       ******   *****        ****    **********${NC}     ${PURPLE}*****     ******        ******  ******${NC}    ${PURPLE}\ \   / /  _ \| \ | |${NC}\n"
printf "${PURPLE}*****       ******    *****     ******   ****** *****${NC}    ${PURPLE}*****      *******    ********  ******${NC}    ${PURPLE} \ \ / /| |_) |  \| |${NC}\n"
printf "${PURPLE}*****       ******     *************    ******   ******${NC}  ${PURPLE}*****       ******************  ******${NC}    ${PURPLE}  \ V / |  __/| |\  |${NC}\n"
printf "${PURPLE}*****       ******       *********     *****      *****${NC}  ${PURPLE}*****          ******** ******  ******${NC}    ${PURPLE}   \_/  |_|   |_| \_|${NC}\n"
echo # Add a blank line for bottom padding

echo -e "${GREEN}================================================${NC}"
echo -e "${GREEN}   Configuração Tailscale VPN - Nexfar          ${NC}"
echo -e "${GREEN}================================================${NC}"
echo ""

# Verificar se está rodando como root
if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}❌ Este script precisa ser executado como root (sudo)${NC}" 
   exit 1
fi

# Detectar distribuição Linux
if [ -f /etc/os-release ]; then
    . /etc/os-release
    DISTRO=$NAME
    echo -e "${BLUE}ℹ️  Sistema detectado: $DISTRO${NC}"
fi

# Verificar se todas as variáveis de ambiente necessárias estão definidas
MODO_INTERATIVO=false
if [ -z "$CLIENTE_NOME" ] || [ -z "$AUTH_KEY" ] || [ -z "$DB_PORTA" ] || [ -z "$DB_TIPO" ]; then
    MODO_INTERATIVO=true
fi

# Se alguma variável não foi definida, usar modo interativo
if [ "$MODO_INTERATIVO" = true ]; then
    echo -e "${YELLOW}⚠️  Modo Interativo${NC}"
    echo -e "${BLUE}Dica: Para execução automatizada, defina as variáveis:${NC}"
    echo -e "${BLUE}  CLIENTE_NOME, AUTH_KEY, DB_PORTA, DB_TIPO${NC}"
    echo ""
    
    # Nome do cliente
    if [ -z "$CLIENTE_NOME" ]; then
        read -p "Nome do Distribuidor/Indústria: " CLIENTE_NOME < /dev/tty
        if [ -z "$CLIENTE_NOME" ]; then
            echo -e "${RED}❌ Nome é obrigatório${NC}"
            exit 1
        fi
    fi
    
    # Auth Key
    if [ -z "$AUTH_KEY" ]; then
        echo ""
        read -p "Cole a Auth Key fornecida por Nexfar: " AUTH_KEY < /dev/tty
        if [ -z "$AUTH_KEY" ]; then
            echo -e "${RED}❌ Auth Key é obrigatória${NC}"
            exit 1
        fi
    fi
    
    # Porta do banco de dados
    if [ -z "$DB_PORTA" ]; then
        echo ""
        echo -e "${BLUE}Portas comuns de bancos de dados:${NC}"
        echo -e "├─ PostgreSQL: 5432"
        echo -e "├─ MySQL/MariaDB: 3306"
        echo -e "├─ Oracle: 1521"
        echo -e "├─ SQL Server: 1433"
        echo -e "├─ MongoDB: 27017"
        echo -e "├─ Redis: 6379"
        echo -e "└─ Cassandra: 9042"
        echo ""
        read -p "Digite a porta do banco de dados: " DB_PORTA < /dev/tty
        if [ -z "$DB_PORTA" ]; then
            echo -e "${RED}❌ Porta do banco de dados é obrigatória${NC}"
            exit 1
        fi
    fi
    
    # Tipo de banco
    if [ -z "$DB_TIPO" ]; then
        echo ""
        read -p "Tipo de banco de dados (postgres/mysql/oracle/mongo/outro): " DB_TIPO < /dev/tty
        DB_TIPO=${DB_TIPO:-db}  # Default para 'db' se vazio
    fi
    
    # Confirmar no modo interativo
    echo ""
    echo -e "${YELLOW}⚠️  Confirme as informações:${NC}"
    echo -e "Cliente: ${GREEN}$CLIENTE_NOME${NC}"
    echo -e "IP do Servidor DB: ${GREEN}$(hostname -I | awk '{print $1}')${NC}"
    echo -e "Porta do DB: ${GREEN}$DB_PORTA${NC}"
    echo -e "Tipo de DB: ${GREEN}$DB_TIPO${NC}"
    echo ""
    read -p "Confirmar e continuar? (s/n): " -n 1 -r < /dev/tty
    echo ""
    if [[ ! $REPLY =~ ^[Ss]$ ]]; then
        echo -e "${RED}❌ Instalação cancelada${NC}"
        exit 1
    fi
else
    echo -e "${GREEN}✓ Modo Automatizado${NC}"
    echo ""
    echo -e "${YELLOW}📋 Configuração detectada:${NC}"
    echo -e "├─ Cliente: ${GREEN}$CLIENTE_NOME${NC}"
    echo -e "├─ Porta: ${GREEN}$DB_PORTA${NC}"
    echo -e "├─ Tipo DB: ${GREEN}$DB_TIPO${NC}"
    echo -e "└─ Auth Key: ${GREEN}${AUTH_KEY:0:15}...${NC}"
fi

# Configurações fixas ou derivadas
PRESTADOR_NOME="Nexfar"
DB_IP=$(hostname -I | awk '{print $1}')

if [ -z "$DB_IP" ]; then
    echo -e "${RED}❌ IP do banco de dados não pôde ser detectado${NC}"
    exit 1
fi

# Converter nomes para lowercase e sem espaços para hostname
CLIENTE_TAG=$(echo "$CLIENTE_NOME" | tr '[:upper:]' '[:lower:]' | tr ' ' '-')
DB_TAG=$(echo "$DB_TIPO" | tr '[:upper:]' '[:lower:]' | tr ' ' '-')

echo ""
echo -e "${YELLOW}🚀 Iniciando instalação...${NC}"
echo ""

# Passo 1: Instalando Tailscale
echo -ne "${GREEN}▶${NC} Passo 1: Instalando Tailscale..."
{
    curl -fsSL https://tailscale.com/install.sh | sh
} > /dev/null 2>&1 &
spinner $! "Passo 1: Instalando Tailscale..."
echo -e " ${GREEN} Passo 1: Instalando Tailscale...${NC}"

# Passo 2: Habilitando roteamento IP
run_with_spinner " Passo 2: Habilitando roteamento IP..." bash -c "
    echo 'net.ipv4.ip_forward = 1' | tee -a /etc/sysctl.d/99-tailscale.conf && \
    echo 'net.ipv6.conf.all.forwarding = 1' | tee -a /etc/sysctl.d/99-tailscale.conf && \
    sysctl -p /etc/sysctl.d/99-tailscale.conf
"

# Passo 3: Conectando ao Tailscale
echo -ne "${GREEN}▶${NC} Passo 3: Conectando ao Tailscale..."

# Hostname descritivo
HOSTNAME="${CLIENTE_TAG}-${DB_TAG}-gateway"

{
    tailscale up --auth-key="$AUTH_KEY" \
      --advertise-routes="$DB_IP/32" \
      --hostname="$HOSTNAME" \
      --advertise-tags=tag:${CLIENTE_TAG}-db \
      --accept-risk=lose-ssh
    
    # Aguardar conexão
    sleep 3
} > /dev/null 2>&1 &
spinner $! "Passo 3: Conectando ao Tailscale..."
echo -e " ${GREEN} Passo 3: Conectando ao Tailscale...${NC}"

# Passo 4: Verificando instalação
echo -ne "${GREEN}▶${NC} Passo 4: Verificando instalação..."

# Pequena pausa para garantir que tudo está pronto
sleep 2

# Verificar status
if tailscale status &> /dev/null; then
    echo -e " ${GREEN}OK${NC}"
    
    # Pegar IP Tailscale
    TAILSCALE_IP=$(tailscale ip -4 2>/dev/null || echo "N/A")
    
    echo ""
    echo -e "${GREEN}================================================${NC}"
    echo -e "${GREEN}🎉 INSTALAÇÃO CONCLUÍDA COM SUCESSO!${NC}"
    echo -e "${GREEN}================================================${NC}"
    echo ""
    echo -e "${YELLOW}📊 Resumo da Configuração:${NC}"
    echo -e "├─ Cliente: ${GREEN}$CLIENTE_NOME${NC}"
    echo -e "├─ IP Tailscale Gateway: ${GREEN}$TAILSCALE_IP${NC}"
    echo -e "├─ Hostname: ${GREEN}$HOSTNAME${NC}"
    echo -e "├─ Rota anunciada: ${GREEN}$DB_IP/32${NC}"
    echo -e "├─ Porta do DB: ${GREEN}$DB_PORTA${NC}"
    echo -e "└─ Tipo do DB: ${GREEN}$DB_TIPO${NC}"
    echo ""
    echo -e "${YELLOW}🔒 Recursos de Segurança:${NC}"
    echo -e "✅ Conexão VPN estabelecida"
    echo -e "✅ Tráfego criptografado end-to-end"
    echo -e "✅ Autenticação via Auth Key"
    echo -e "✅ Controle de acesso via ACLs no Tailscale"
    echo ""
    echo -e "${YELLOW}📧 Envie para $PRESTADOR_NOME:${NC}"
    echo -e "├─ IP do Banco: ${GREEN}$DB_IP${NC}"
    echo -e "├─ Porta: ${GREEN}$DB_PORTA${NC}"
    echo -e "├─ Tipo: ${GREEN}$DB_TIPO${NC}"
    echo -e "└─ Status: ${GREEN}Pronto para conexão${NC}"
    
    # Criar arquivo de configuração
    CONFIG_FILE="/etc/tailscale/client-config.json"
    mkdir -p /etc/tailscale
    cat > "$CONFIG_FILE" << EOF
{
  "cliente": "$CLIENTE_NOME",
  "prestador": "$PRESTADOR_NOME",
  "db_ip": "$DB_IP",
  "db_porta": "$DB_PORTA",
  "db_tipo": "$DB_TIPO",
  "tailscale_ip": "$TAILSCALE_IP",
  "hostname": "$HOSTNAME",
  "data_instalacao": "$(date -Iseconds)",
  "auth_key_prefix": "${AUTH_KEY:0:15}..."
}
EOF
    
    echo ""
    echo -e "${GREEN}📄 Configuração salva em: $CONFIG_FILE${NC}"
    
else
    echo -e " ${RED}ERRO${NC}"
    echo -e "${RED}❌ Erro ao conectar Tailscale${NC}"
    echo -e "${YELLOW}Verifique os logs com: journalctl -u tailscaled -n 50${NC}"
    exit 1
fi

echo ""
echo -e "${GREEN}================================================${NC}"
echo -e "${GREEN}✅ Processo finalizado com sucesso!${NC}"
echo -e "${GREEN}================================================${NC}"

echo ""
echo -e "${YELLOW}💡 Comandos úteis:${NC}"
echo -e "├─ Ver status: ${GREEN}tailscale status${NC}"
echo -e "├─ Ver logs: ${GREEN}journalctl -u tailscaled -f${NC}"
echo -e "├─ Ver IP: ${GREEN}tailscale ip${NC}"
echo -e "└─ Ver config: ${GREEN}cat /etc/tailscale/client-config.json${NC}"

echo ""
echo -e "${YELLOW}📌 NOTA IMPORTANTE:${NC}"
echo -e "A segurança e controle de acesso devem ser configurados"
echo -e "através das ACLs (Access Control Lists) no painel do Tailscale."
echo -e "Consulte a documentação da Nexfar para configurações recomendadas."
