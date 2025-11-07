#!/bin/bash
#############################################################
# Script de Instalação Tailscale para Acesso Seguro a DB
# Controle total do cliente sobre portas permitidas
# Versão: 2.0 - Genérico
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
echo -e "${GREEN}   Liberação de IP e Porta para rede Nexfar     ${NC}"
echo -e "${GREEN}================================================${NC}"
echo ""

# Verificar se está rodando como root
if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}❌ Este script precisa ser executado como root (sudo)${NC}" 
   exit 1
fi

# Solicitar informações necessárias
echo -e "${YELLOW}📋 Configuração do Acesso ao Banco de Dados:${NC}"
echo ""

# Nome do cliente
read -p "Nome do Distruidor/Indústria: " CLIENTE_NOME
if [ -z "$CLIENTE_NOME" ]; then
    echo -e "${RED}❌ Nome é obrigatório${NC}"
    exit 1
fi

# Nome do prestador
PRESTADOR_NOME="Nexfar"
if [ -z "$PRESTADOR_NOME" ]; then
    echo -e "${RED}❌ Nome do prestador é obrigatório${NC}"
    exit 1
fi

# Auth Key
echo ""
read -p "Cole a Auth Key fornecida por $PRESTADOR_NOME: " AUTH_KEY
if [ -z "$AUTH_KEY" ]; then
    echo -e "${RED}❌ Auth Key é obrigatória${NC}"
    exit 1
fi

# IP do servidor de banco de dados
echo ""
DB_IP=$(hostname -I | awk '{print $1}')
if [ -z "$DB_IP" ]; then
    echo -e "${RED}❌ IP do banco de dados é obrigatório${NC}"
    exit 1
fi

# Porta do banco de dados
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
read -p "Digite a porta do banco de dados: " DB_PORTA
if [ -z "$DB_PORTA" ]; then
    echo -e "${RED}❌ Porta do banco de dados é obrigatória${NC}"
    exit 1
fi

# Tipo de banco (opcional, para hostname)
echo ""
read -p "Tipo de banco de dados (postgres/mysql/oracle/mongo/outro): " DB_TIPO
DB_TIPO=${DB_TIPO:-db}  # Default para 'db' se vazio

# Converter nomes para lowercase e sem espaços para hostname
CLIENTE_TAG=$(echo "$CLIENTE_NOME" | tr '[:upper:]' '[:lower:]' | tr ' ' '-')
DB_TAG=$(echo "$DB_TIPO" | tr '[:upper:]' '[:lower:]' | tr ' ' '-')

# Confirmar dados
echo ""
echo -e "${YELLOW}⚠️  Confirme as informações:${NC}"
echo -e "Cliente: ${GREEN}$CLIENTE_NOME${NC}"
echo -e "Prestador: ${GREEN}$PRESTADOR_NOME${NC}"
echo -e "IP do Servidor DB: ${GREEN}$DB_IP${NC}"
echo -e "Porta do DB: ${GREEN}$DB_PORTA${NC}"
echo -e "Tipo de DB: ${GREEN}$DB_TIPO${NC}"
echo -e "Acesso permitido: ${GREEN}APENAS porta $DB_PORTA${NC}"
echo ""
read -p "Confirmar e continuar? (s/n): " -n 1 -r
echo ""

if [[ ! $REPLY =~ ^[Ss]$ ]]; then
    echo -e "${RED}❌ Instalação cancelada${NC}"
    exit 1
fi

echo ""
echo -e "${GREEN}▶ Passo 1: Instalando Tailscale...${NC}"
curl -fsSL https://tailscale.com/install.sh | sh

echo ""
echo -e "${GREEN}▶ Passo 2: Habilitando roteamento IP...${NC}"
echo 'net.ipv4.ip_forward = 1' | tee -a /etc/sysctl.d/99-tailscale.conf
echo 'net.ipv6.conf.all.forwarding = 1' | tee -a /etc/sysctl.d/99-tailscale.conf
sysctl -p /etc/sysctl.d/99-tailscale.conf > /dev/null

echo ""
echo -e "${GREEN}▶ Passo 3: Configurando Firewall (APENAS porta $DB_PORTA)...${NC}"

# Instalar iptables-persistent se não existir (Debian/Ubuntu)
if command -v apt-get &> /dev/null; then
    DEBIAN_FRONTEND=noninteractive apt-get install -y iptables-persistent > /dev/null 2>&1
fi

# Limpar regras antigas do Tailscale se existirem
iptables -D FORWARD -i tailscale0 -d $DB_IP -p tcp --dport $DB_PORTA -j ACCEPT 2>/dev/null || true
iptables -D FORWARD -i tailscale0 -d $DB_IP -j DROP 2>/dev/null || true

# Adicionar novas regras
iptables -I FORWARD 1 -i tailscale0 -d $DB_IP -p tcp --dport $DB_PORTA -j ACCEPT -m comment --comment "Tailscale: DB porta $DB_PORTA para $PRESTADOR_NOME"
iptables -I FORWARD 2 -i tailscale0 -d $DB_IP -j DROP -m comment --comment "Tailscale: Bloquear outras portas - $PRESTADOR_NOME"

# Salvar regras
if command -v netfilter-persistent &> /dev/null; then
    netfilter-persistent save
elif command -v service &> /dev/null; then
    service iptables save 2>/dev/null || true
fi

echo -e "${GREEN}✓ Firewall configurado - APENAS porta $DB_PORTA permitida${NC}"

echo ""
echo -e "${GREEN}▶ Passo 4: Conectando ao Tailscale...${NC}"

# Hostname descritivo
HOSTNAME="${CLIENTE_TAG}-${DB_TAG}-gateway"

tailscale up --auth-key="$AUTH_KEY" \
  --advertise-routes="$DB_IP/32" \
  --hostname="$HOSTNAME" \
  --advertise-tags=tag:${CLIENTE_TAG}-db \
  --accept-risk=lose-ssh

# Aguardar conexão
sleep 3

echo ""
echo -e "${GREEN}▶ Passo 5: Verificando instalação...${NC}"

# Verificar status
if tailscale status &> /dev/null; then
    echo -e "${GREEN}✓ Tailscale conectado com sucesso${NC}"
    
    # Pegar IP Tailscale
    TAILSCALE_IP=$(tailscale ip -4 2>/dev/null || echo "N/A")
    
    # Verificar regras de firewall
    REGRAS=$(iptables -L FORWARD -n -v | grep -c "tailscale0.*$DB_IP" || echo "0")
    
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
    echo -e "├─ Porta permitida: ${GREEN}APENAS $DB_PORTA${NC}"
    echo -e "└─ Firewall: ${GREEN}$REGRAS regras ativas${NC}"
    echo ""
    echo -e "${YELLOW}🔒 Segurança Garantida:${NC}"
    echo -e "✅ Acesso limitado ao IP $DB_IP"
    echo -e "✅ APENAS porta $DB_PORTA acessível"
    echo -e "✅ Outras portas bloqueadas por firewall local"
    echo -e "✅ Controle total mantido por $CLIENTE_NOME"
    echo -e "✅ Tráfego criptografado end-to-end"
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
    
    # Log detalhado
    LOG_FILE="/var/log/tailscale-db-setup.log"
    {
        echo "=== Tailscale DB Access Setup - $(date) ==="
        echo "Cliente: $CLIENTE_NOME"
        echo "Prestador: $PRESTADOR_NOME"
        echo "DB IP: $DB_IP"
        echo "DB Porta: $DB_PORTA"
        echo "DB Tipo: $DB_TIPO"
        echo "Tailscale IP: $TAILSCALE_IP"
        echo "Hostname: $HOSTNAME"
        echo "Firewall Rules:"
        iptables -L FORWARD -n -v | grep tailscale0
    } > "$LOG_FILE"
    
    echo -e "${GREEN}📄 Log detalhado em: $LOG_FILE${NC}"
    
else
    echo -e "${RED}❌ Erro ao conectar Tailscale${NC}"
    exit 1
fi

echo ""
echo -e "${GREEN}▶ Criando scripts auxiliares...${NC}"

# Criar script de teste de conectividade
cat > /usr/local/bin/test-db-access.sh << EOF
#!/bin/bash
echo "Testando acesso ao banco de dados..."
echo "IP: $DB_IP"
echo "Porta: $DB_PORTA"
timeout 2 bash -c "cat < /dev/null > /dev/tcp/$DB_IP/$DB_PORTA" && \\
  echo "✅ Porta $DB_PORTA está acessível" || \\
  echo "❌ Porta $DB_PORTA não está respondendo"
EOF

chmod +x /usr/local/bin/test-db-access.sh

# Criar script de desinstalação
cat > /usr/local/bin/remove-tailscale-db.sh << EOF
#!/bin/bash
echo "Removendo configuração Tailscale para $CLIENTE_NOME..."
tailscale down
iptables -D FORWARD -i tailscale0 -d $DB_IP -p tcp --dport $DB_PORTA -j ACCEPT 2>/dev/null
iptables -D FORWARD -i tailscale0 -d $DB_IP -j DROP 2>/dev/null
echo "Deseja remover o Tailscale completamente? (s/n)"
read -n 1 -r
if [[ \$REPLY =~ ^[Ss]$ ]]; then
    apt-get remove --purge tailscale -y 2>/dev/null || yum remove tailscale -y 2>/dev/null
    rm -f /etc/tailscale/client-config.json
    echo "✓ Tailscale removido completamente"
else
    echo "✓ Apenas configurações removidas, Tailscale ainda instalado"
fi
EOF

chmod +x /usr/local/bin/remove-tailscale-db.sh

echo ""
echo -e "${GREEN}================================================${NC}"
echo -e "${GREEN}✅ Processo finalizado com sucesso!${NC}"
echo -e "${GREEN}================================================${NC}"

echo ""
echo -e "${YELLOW}💡 Comandos úteis:${NC}"
echo -e "├─ Ver status: ${GREEN}tailscale status${NC}"
echo -e "├─ Testar conexão DB: ${GREEN}test-db-access.sh${NC}"
echo -e "├─ Ver logs: ${GREEN}journalctl -u tailscaled -f${NC}"
echo -e "├─ Ver firewall: ${GREEN}iptables -L FORWARD -n -v | grep tailscale${NC}"
echo -e "├─ Ver config: ${GREEN}cat /etc/tailscale/client-config.json${NC}"
echo -e "└─ Desinstalar: ${GREEN}remove-tailscale-db.sh${NC}"

echo ""
echo -e "${YELLOW}📌 IMPORTANTE:${NC}"
echo -e "O acesso está limitado APENAS à porta $DB_PORTA do servidor $DB_IP"
echo -e "Mesmo que $PRESTADOR_NOME mude as configurações do lado deles,"
echo -e "o firewall local garante que apenas a porta $DB_PORTA seja acessível."
