# Identidade Food2C no Chatwoot 4.16.2

Esta branch usa os logos, as cores e a fonte da landing page Food2C. O painel,
login, ícones do navegador e manifest usam verde `#004747`, laranja `#EB7F49`
e Poppins. Os arquivos da fonte estão em `public/brand-assets/fonts/` com a
licença SIL OFL.

## Atualizar uma instalação existente

O Chatwoot guarda `INSTALLATION_NAME`, `BRAND_NAME` e URLs dos logos no
PostgreSQL. Alterar os valores padrão em `config/installation_config.yml` só
afeta instalações novas. Após subir a imagem desta branch, execute uma vez:

```bash
sudo docker compose -p chatwoot -f docker-compose.yaml -f docker-compose.food2c.override.yaml exec rails bundle exec rake food2c:apply_branding
```

A task só atualiza as oito opções de marca listadas no código e pode ser
executada de novo sem alterar outras configurações. Os canais, contatos,
mensagens, tabulações e segredos continuam no banco e no `.env` existentes.

Para a instalação Food2C no Lightsail, faça o checkout desta branch na pasta
do código usada pelo build local. Preserve o projeto Compose `chatwoot`, o
arquivo `.env` atual e os volumes. Depois:

```bash
sudo docker compose -p chatwoot -f docker-compose.yaml -f docker-compose.food2c.override.yaml build rails
sudo docker compose -p chatwoot -f docker-compose.yaml -f docker-compose.food2c.override.yaml up -d --no-deps --no-build --pull never --force-recreate rails sidekiq
sudo docker compose -p chatwoot -f docker-compose.yaml -f docker-compose.food2c.override.yaml exec rails bundle exec rake food2c:apply_branding
```

O arquivo de override precisa apontar `rails` e `sidekiq` para a imagem
construída. Os logos incluídos na imagem usam os caminhos padrão
`/brand-assets/logo.svg`, `/brand-assets/logo_dark.svg` e
`/brand-assets/logo_thumbnail.svg`. Montagens de arquivos nesses mesmos
caminhos substituem o conteúdo da imagem; confira as montagens antes de subir.

Depois do deploy, abra login e atendimento em janela privada, confira o logo
nas duas aparências, favicon, menu, cores e fonte. A tela de tabulação e o
relatório são servidos pelo repositório `whatsapp-chatwoot-service` e precisam
do deploy próprio para receber o mesmo visual.
