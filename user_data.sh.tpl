#!/bin/bash
set -euxo pipefail

curl -fsSL https://get.docker.com | sh
systemctl enable docker
systemctl start docker

mkdir -p /opt/newapi/data
cd /opt/newapi

cat > docker-compose.yml <<'EOF'
services:
  new-api:
    image: calciumion/new-api:latest
    container_name: new-api
    restart: always
    environment:
      - TZ=Asia/Shanghai
    volumes:
      - ./data:/data
    networks:
      - newapi

  caddy:
    image: caddy:2-alpine
    container_name: caddy
    restart: always
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./Caddyfile:/etc/caddy/Caddyfile
      - caddy_data:/data
      - caddy_config:/config
    networks:
      - newapi
    depends_on:
      - new-api

networks:
  newapi:

volumes:
  caddy_data:
  caddy_config:
EOF

cat > Caddyfile <<'EOF'
%{ if domain_name != "" ~}
${domain_name} {
    reverse_proxy new-api:3000
}
%{ else ~}
:80 {
    reverse_proxy new-api:3000
}
%{ endif ~}
EOF

docker compose up -d
