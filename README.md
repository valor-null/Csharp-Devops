# 🐋 EasyMoto — Sprint 3 (DevOps Tools & Cloud Computing)

> **EasyMoto** organiza o dia a dia dos pátios e da frota (Usuarios, Notificações, Motos) com **API .NET 8** publicada em **Azure App Service** e dados no **Azure SQL**.
**Nessa entrega**: disponibilizamos a API em **PaaS (Azure App Service)** com **banco de dados em nuvem (Azure SQL)**, automação via **Azure CLI** e **CI/CD** com GitHub Actions.
---
## ⚙️ Stack técnica

* **Linguagem**: C# / .NET 8
* **PaaS**: Azure App Service 
* **Banco**: Azure SQL Database
* **Automação**: Azure CLI (Bash)
* **CI/CD**: GitHub Actions
* **API Docs**: Swagger 

---
## 🚀 Deploy na Azure (passo a passo)
> O repositório traz dois scripts: um para **banco** e outro para **aplicação**.

### Passo 1 — Banco de Dados (Azure SQL)
Crie o script, dê permissão e edite:
```bash
touch cli-scripts/create-sql-server.sh
chmod +x cli-scripts/create-sql-server.sh
nano cli-scripts/create-sql-server.sh
```
Cole o conteúdo abaixo (**sanitizado**, use sua senha real em vez de `<SUA_SENHA_FORTE>`):
```bash
#!/bin/bash
set -e

RG="rg-easymoto"
LOCATION="brazilsouth"
SERVER_NAME="sqlserver-rm557177"
USERNAME="admsql"
PASSWORD="<SUA_SENHA_FORTE>"  
DBNAME="easymotodb"

echo ">> Criando o grupo de recursos: $RG..."
az group create --name "$RG" --location "$LOCATION" >/dev/null

echo ">> Criando o servidor SQL: $SERVER_NAME..."
az sql server create \
  -l "$LOCATION" -g "$RG" -n "$SERVER_NAME" \
  -u "$USERNAME" -p "$PASSWORD" \
  --enable-public-network true --minimal-tls-version 1.2 >/dev/null

echo ">> Criando o banco de dados: $DBNAME..."
az sql db create \
  -g "$RG" -s "$SERVER_NAME" -n "$DBNAME" \
  --service-objective Basic \
  --backup-storage-redundancy Local \
  --zone-redundant false >/dev/null

echo ">> Configurando a regra de firewall: AllowAll (0.0.0.0 - 255.255.255.255)"
az sql server firewall-rule create \
  -g "$RG" -s "$SERVER_NAME" \
  -n AllowAll --start-ip-address 0.0.0.0 --end-ip-address 255.255.255.255 >/dev/null

echo "====================================="
echo "Infra de banco criada com sucesso!"
echo "Servidor: ${SERVER_NAME}.database.windows.net"
echo "Banco:    ${DBNAME}"
echo "Usuário:  ${USERNAME}"
echo
echo "Connection string ADO.NET:"
echo "Server=tcp:${SERVER_NAME}.database.windows.net,1433;Database=${DBNAME};User ID=${USERNAME};Password=${PASSWORD};Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;"
echo "====================================="
```
Execute o script:
```bash
bash cli-scripts/create-sql-server.sh
```
> **Aplicar DDL**: após criar o banco, abra o **Azure Portal → SQL Database → Query Editor
---

### Passo 2 — Aplicação (App Service + App Insights + Settings + CI/CD)
Crie o script, dê permissão e edite:
```bash
touch cli-scripts/deploy-easymoto.sh
chmod +x cli-scripts/deploy-easymoto.sh
nano cli-scripts/deploy-easymoto.sh
```
Cole o conteúdo abaixo (**substitua** `<SUA_SENHA_FORTE>` e ajuste nomes se necessário):
```bash
#!/bin/bash
set -e

export RESOURCE_GROUP_NAME="rg-easymoto"
export WEBAPP_NAME="web-easymoto-rm557177"
export APP_SERVICE_PLAN="plan-easymoto-b1"
export LOCATION="brazilsouth"
export RUNTIME="DOTNETCORE|8.0"
export GITHUB_REPO_NAME="valor-null/Csharp-Devops"
export BRANCH="main"
export APP_INSIGHTS_NAME="ai-easymoto"

export DB_SERVER_NAME="sqlserver-rm557177"
export DB_NAME="easymotodb"
export DB_USER="admsql"
export DB_PASSWORD="<SUA_SENHA_FORTE>"

export ADO_NET="Server=tcp:${DB_SERVER_NAME}.database.windows.net,1433;Database=${DB_NAME};User ID=${DB_USER};Password=${DB_PASSWORD};Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;"

echo "Iniciando o deploy da aplicação e infraestrutura..."

az monitor app-insights component create \
  --app "$APP_INSIGHTS_NAME" \
  --location "$LOCATION" \
  --resource-group "$RESOURCE_GROUP_NAME" \
  --application-type web >/dev/null

az appservice plan create \
  --name "$APP_SERVICE_PLAN" \
  --resource-group "$RESOURCE_GROUP_NAME" \
  --location "$LOCATION" \
  --sku B1 \
  --is-linux >/dev/null

az webapp create \
  --name "$WEBAPP_NAME" \
  --resource-group "$RESOURCE_GROUP_NAME" \
  --plan "$APP_SERVICE_PLAN" \
  --runtime "$RUNTIME" >/dev/null

# Habilita credenciais de publicação (Kudu/SCM)
az resource update \
  --resource-group "$RESOURCE_GROUP_NAME" \
  --namespace Microsoft.Web \
  --resource-type basicPublishingCredentialsPolicies \
  --name scm \
  --parent sites/"$WEBAPP_NAME" \
  --set properties.allow=true >/dev/null

# Obtém a connection string do App Insights
CONNECTION_STRING=$(az monitor app-insights component show \
  --app "$APP_INSIGHTS_NAME" \
  --resource-group "$RESOURCE_GROUP_NAME" \
  --query connectionString -o tsv)

# App Settings
az webapp config appsettings set \
  --name "$WEBAPP_NAME" \
  --resource-group "$RESOURCE_GROUP_NAME" \
  --settings \
    APPLICATIONINSIGHTS_CONNECTION_STRING="$CONNECTION_STRING" \
    ASPNETCORE_ENVIRONMENT="Production" \
    ASPNETCORE_URLS="http://0.0.0.0:8080" \
    WEBSITES_PORT="8080" >/dev/null

# Connection String (SQL Azure)
az webapp config connection-string set \
  --name "$WEBAPP_NAME" \
  --resource-group "$RESOURCE_GROUP_NAME" \
  --settings DefaultConnection="$ADO_NET" \
  --connection-string-type SQLAzure >/dev/null

# Always On
az webapp config set \
  --resource-group "$RESOURCE_GROUP_NAME" \
  --name "$WEBAPP_NAME" \
  --always-on true >/dev/null

# Startup (ajuste o nome do assembly se necessário)
az webapp config set \
  --resource-group "$RESOURCE_GROUP_NAME" \
  --name "$WEBAPP_NAME" \
  --startup-file "dotnet EasyMoto.Api.dll" >/dev/null

# Reinicia o webapp
az webapp restart \
  --name "$WEBAPP_NAME" \
  --resource-group "$RESOURCE_GROUP_NAME" >/dev/null

# Conecta App Insights ao WebApp
az monitor app-insights component connect-webapp \
  --app "$APP_INSIGHTS_NAME" \
  --web-app "$WEBAPP_NAME" \
  --resource-group "$RESOURCE_GROUP_NAME" >/dev/null

# Configura GitHub Actions para CI/CD
az webapp deployment github-actions add \
  --name "$WEBAPP_NAME" \
  --resource-group "$RESOURCE_GROUP_NAME" \
  --repo "$GITHUB_REPO_NAME" \
  --branch "$BRANCH" \
  --login-with-github

echo "====================================="
echo "Deploy concluído com sucesso!"
echo "Site:     https://${WEBAPP_NAME}.azurewebsites.net"
echo "Swagger:  https://${WEBAPP_NAME}.azurewebsites.net/swagger/index.html"
echo "====================================="
```
Execute o script:
```bash
bash cli-scripts/deploy-easymoto.sh
```

> **Após o deploy**: acesse `https://web-easymoto-rm557177.azurewebsites.net//swagger/index.html`

---

## 👥 Equipe:

* ⭐️ **Valéria Conceição Dos Santos** — RM: **557177**  
* ⭐️ **Mirela Pinheiro Silva Rodrigues** — RM: **558191**
* ⭐️ **Luiz Eduardo Da Silva Pinto** — RM: **555213**
---


