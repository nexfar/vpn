# Conexão segura via VPN

## 🎯 Visão Geral

Guia para configuração de VPN segura do cliente com a Nexfar, viabilizando o acesso a banco de dados através de VPN site-to-site. Instalação é feita através de scripts, facilitando o processo de instalação.

## 📦 Scripts Disponíveis

### Linux
- `install.sh` - Script principal para Linux/Unix

### Windows
- `install.ps1` - PowerShell (Windows 8.1+)
- `install.bat` - Batch (Windows 7+)

## 🚀 Instalação Rápida

### Linux (Recomendado - Uma linha)

**Com curl:**
```bash
curl -fsSL https://raw.githubusercontent.com/nexfar/vpn/main/install.sh | sudo bash
```

**Com wget:**
```bash
wget -qO- https://raw.githubusercontent.com/nexfar/vpn/main/install.sh | sudo bash
```

### Linux (Download manual)
```bash
# Baixar o script
curl -fsSL https://raw.githubusercontent.com/nexfar/vpn/main/install.sh -o install.sh

# Tornar executável
chmod +x install.sh

# Executar
sudo ./install.sh
```

### Windows PowerShell

**Download e execução direta:**
```powershell
# Como Administrador
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/nexfar/vpn/main/install.ps1" -OutFile "$env:TEMP\install.ps1"
& "$env:TEMP\install.ps1"
```

**Download manual:**
```powershell
# Como Administrador
# 1. Baixe o arquivo install.ps1 do repositório
# 2. Execute:
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
.\install.ps1
```

### Windows Batch

**Download manual:**
```batch
# Como Administrador
# 1. Baixe o arquivo install.bat do repositório
# 2. Execute:
install.bat
```

## ⚙️ Modos de Execução

### Modo Interativo (Padrão)
O script perguntará:
- Nome do Distribuidor/Indústria
- Auth Key fornecida
- Porta do banco de dados
- Tipo de banco de dados

### Modo Automatizado

**Linux:**
```bash
export CLIENTE_NOME="Empresa ABC"
export AUTH_KEY="tskey-auth-xxxxx"
export DB_PORTA="5432"
export DB_TIPO="postgres"
sudo ./install.sh
```

**Linux (uma linha com variáveis):**
```bash
curl -fsSL https://raw.githubusercontent.com/nexfar/vpn/main/install.sh | \
  sudo CLIENTE_NOME="Empresa ABC" \
  AUTH_KEY="tskey-auth-xxxxx" \
  DB_PORTA="5432" \
  DB_TIPO="postgres" \
  bash
```

**PowerShell:**
```powershell
$env:CLIENTE_NOME = "Empresa ABC"
$env:AUTH_KEY = "tskey-auth-xxxxx"
$env:DB_PORTA = "5432"
$env:DB_TIPO = "postgres"
.\install.ps1
```

**Batch:**
```batch
SET CLIENTE_NOME=Empresa ABC
SET AUTH_KEY=tskey-auth-xxxxx
SET DB_PORTA=5432
SET DB_TIPO=postgres
install.bat
```

## 🔒 Segurança

### O que o script configura:
- ✅ **Instalação do Tailscale:** Cliente VPN seguro que conecta a máquina específica a rede da Nexfar
- ✅ **Roteamento IP:** Habilita encaminhamento de pacotes
- ✅ **Autenticação:** Via Auth Key fornecida
- ✅ **Criptografia:** End-to-end automática

### O que NÃO é configurado (gerenciado via ACLs Tailscale):
- Regras de firewall local
- Controle de acesso granular
- Políticas de rede

## 🔧 Comandos Úteis

### Verificar status
```bash
# Linux
tailscale status

# Windows
"C:\Program Files\Tailscale\tailscale.exe" status
```

### Ver IP Tailscale
```bash
# Linux
tailscale ip

# Windows
"C:\Program Files\Tailscale\tailscale.exe" ip
```

### Ver configuração salva
```bash
# Linux
cat /etc/tailscale/client-config.json

# Windows PowerShell
Get-Content "$env:ProgramData\Tailscale\client-config.json"

# Windows Batch
type "%ProgramData%\Tailscale\client-config.json"
```

### Ver logs
```bash
# Linux
journalctl -u tailscaled -f

# Windows PowerShell
Get-EventLog -LogName Application -Source Tailscale -Newest 50
```

## ❓ Solução de Problemas

### Erro: "Script não pode ser executado"
- **Linux:** Verificar permissões com `chmod +x install.sh`
- **Windows PowerShell:** Executar como Administrador e ajustar ExecutionPolicy
- **Windows Batch:** Executar como Administrador

### Erro: "Auth Key inválida"
- Verificar se a Auth Key está correta
- Confirmar que a Auth Key não expirou
- Solicitar nova Auth Key se necessário
- Verificar se não há espaços extras no início/fim da chave

### Erro: "Tailscale não conecta"
```bash
# Linux - Ver logs detalhados
journalctl -u tailscaled -n 50

# Windows - Event Viewer
Get-EventLog -LogName Application -Source Tailscale
```

### Erro: "IP não detectado"
- Verificar se a interface de rede está ativa
- Confirmar que há um IP válido atribuído
- Executar `ipconfig` (Windows) ou `ip addr` (Linux) para verificar

### Erro: "Permissão negada"
- **Linux:** Executar com `sudo`
- **Windows:** Executar como Administrador (botão direito → "Executar como administrador")

## 📊 Portas Comuns de Bancos de Dados

| Banco de Dados | Porta Padrão |
|----------------|--------------|
| PostgreSQL     | 5432         |
| MySQL/MariaDB  | 3306         |
| SQL Server     | 1433         |
| Oracle         | 1521         |
| MongoDB        | 27017        |
| Redis          | 6379         |
| Cassandra      | 9042         |

## 📋 O que enviar para a Nexfar após instalação

Após a instalação bem-sucedida, envie as seguintes informações:

- ✅ IP do Banco de Dados
- ✅ Porta do Banco de Dados
- ✅ Tipo do Banco de Dados
- ✅ Status: "Pronto para conexão"

Essas informações são exibidas no final da instalação e também salvas no arquivo de configuração.

## 🔗 Links Úteis

- [Documentação Tailscale](https://tailscale.com/kb/)
- [GitHub - Repositório VPN Nexfar](https://github.com/nexfar/vpn)
- [Tailscale ACLs](https://tailscale.com/kb/1018/acls/)

## 📝 Notas Importantes

1. **Segurança:** A segurança e controle de acesso devem ser configurados através das ACLs (Access Control Lists) no painel do Tailscale. Consulte a documentação da Nexfar para configurações recomendadas.

2. **Conectividade:** Certifique-se de que a máquina tem acesso à internet para baixar e instalar o Tailscale.

3. **Firewall:** O script não configura regras de firewall local. O controle de acesso é gerenciado via ACLs no Tailscale.

4. **Backup:** O script cria um arquivo de configuração com os detalhes da instalação para referência futura.

5. **Suporte:** Para questões ou problemas, entre em contato com o suporte da Nexfar.
