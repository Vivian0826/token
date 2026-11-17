#!/bin/bash
set -euxo pipefail

fallocate -l 2G /swapfile
chmod 600 /swapfile
mkswap /swapfile
swapon /swapfile
echo '/swapfile none swap sw 0 0' >> /etc/fstab

curl -fsSL https://get.docker.com | sh
systemctl enable docker
systemctl start docker

mkdir -p /opt/newapi/data
cd /opt/newapi

cat > .env <<EOF
OPENAI_PROXY_URL=http://new-api:3000/v1
ENABLED_OLLAMA=0
INFISICAL_DB_PASSWORD=$(openssl rand -hex 20)
INFISICAL_ENCRYPTION_KEY=$(openssl rand -hex 16)
INFISICAL_AUTH_SECRET=$(openssl rand -base64 32)
EOF
chmod 600 .env

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

  lobe-chat:
    image: lobehub/lobe-chat:latest
    container_name: lobe-chat
    restart: always
    env_file:
      - .env
    networks:
      - newapi

  infisical-db:
    image: postgres:14-alpine
    container_name: infisical-db
    restart: always
    environment:
      - POSTGRES_USER=infisical
      - POSTGRES_DB=infisical
      - POSTGRES_PASSWORD=$${INFISICAL_DB_PASSWORD}
    volumes:
      - infisical_pg_data:/var/lib/postgresql/data
    networks:
      - newapi
    healthcheck:
      test: "pg_isready --username=infisical && psql --username=infisical --list"
      interval: 5s
      timeout: 10s
      retries: 10

  infisical-redis:
    image: redis:7-alpine
    container_name: infisical-redis
    restart: always
    environment:
      - ALLOW_EMPTY_PASSWORD=yes
    networks:
      - newapi
    volumes:
      - infisical_redis_data:/data

  infisical:
    image: infisical/infisical:latest
    container_name: infisical
    restart: always
    depends_on:
      infisical-db:
        condition: service_healthy
      infisical-redis:
        condition: service_started
    environment:
      - NODE_ENV=production
      - AUTH_SECRET=$${INFISICAL_AUTH_SECRET}
      - ENCRYPTION_KEY=$${INFISICAL_ENCRYPTION_KEY}
      - DB_CONNECTION_URI=postgres://infisical:$${INFISICAL_DB_PASSWORD}@infisical-db:5432/infisical
      - REDIS_URL=redis://infisical-redis:6379
      - SITE_URL=http://${public_ip}:9000
    networks:
      - newapi

  caddy:
    image: caddy:2-alpine
    container_name: caddy
    restart: always
    ports:
      - "80:80"
      - "443:443"
      - "8080:8080"
      - "9000:9000"
    volumes:
      - ./Caddyfile:/etc/caddy/Caddyfile
      - caddy_data:/data
      - caddy_config:/config
    networks:
      - newapi
    depends_on:
      - new-api
      - lobe-chat
      - infisical

networks:
  newapi:

volumes:
  caddy_data:
  caddy_config:
  infisical_pg_data:
  infisical_redis_data:
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

:8080 {
    reverse_proxy lobe-chat:3210
}

:9000 {
    reverse_proxy infisical:8080
}
EOF

docker compose up -d
