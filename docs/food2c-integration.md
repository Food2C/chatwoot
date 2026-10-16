# Integração Food2C no Chatwoot 4.16.2

Esta branch parte da tag oficial `v4.16.2`. Ela adiciona **Nova conversa
Food2C** em Contatos, **Relatório Food2C** no menu Relatórios e exige
`food2c_tabulation` antes de resolver atendimentos nas contas configuradas.

## Configuração

Defina estas variáveis **no servidor Chatwoot** (web e workers):

```text
FOOD2C_TEMPLATE_APP_URL=https://api.food2c.com.br/whatsapp-chatwoot/template-app
FOOD2C_TEMPLATE_APP_SECRET=<mesmo valor de TEMPLATE_APP_SECRET no serviço Food2C>
FOOD2C_TABULATION_REQUIRED_ACCOUNT_IDS=1
```

O proxy usa o token somente no servidor, encaminha as chamadas com a sessão do
agente e restringe os dados à conta da URL. As páginas `/new` e `/report` do
serviço de integração precisam estar implantadas antes de ativar os atalhos.
Mantenha a Dashboard App Food2C existente para tabulação e histórico durante
as conversas. Somente administradores da conta podem alterar as opções de
tabulação pelo proxy.

A exigência de tabulação é aplicada pelo modelo `Conversation`, incluindo
resoluções pela interface e pela API. Antes de resolver, o Chatwoot confirma
que o valor está sincronizado no relatório do serviço Food2C. Se o serviço
estiver indisponível, a resolução fica bloqueada até que a confirmação volte
a funcionar. Se a conta não estiver listada em
`FOOD2C_TABULATION_REQUIRED_ACCOUNT_IDS`, o fluxo padrão permanece.

Um valor preenchido diretamente nos atributos personalizados do Chatwoot sem
registro `synced` correspondente no DocumentDB não permite encerrar a conversa.
Tabule pela Dashboard App Food2C para manter a observação e o relatório
completos.

## Docker Compose no Lightsail

No fork, use a branch `food2c/chatwoot-4.16.2-integration`. O compose de
produção oficial usa `chatwoot/chatwoot:latest`; o arquivo
`docker-compose.food2c.yaml` substitui essa imagem pelo build do fork para os
serviços `rails` e `sidekiq`.

No arquivo `.env` da instalação, configure as três variáveis acima. O ID `1`
foi confirmado pela URL da conta Food2C (`/app/accounts/1/`).

Antes da troca, faça um backup do PostgreSQL e do arquivo `.env` da instância.
Identifique o projeto Compose em uso com `docker compose ls`. Faça o checkout da
branch na pasta da instalação existente e preserve o mesmo nome de projeto; os
volumes `postgres_data` e `storage_data` dependem dele. Não copie um `.env`
exemplo sobre o arquivo real. Na pasta da instalação no Lightsail:

```bash
docker compose -f docker-compose.production.yaml -f docker-compose.food2c.yaml build rails
docker compose -f docker-compose.production.yaml -f docker-compose.food2c.yaml up -d rails sidekiq
```

Confirme a versão e as variáveis nos contêineres após subir. O build local deve
ser feito sobre esta branch; puxar apenas a imagem oficial do Docker Hub não
inclui as alterações Food2C.
