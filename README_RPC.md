# RPC (L1/L2/L3)

RPC configs are kept separate from the main `cortensord` states.

Folders:
- `salt/rpc/` (state stubs for L1/L2/L3)
- `pillar/rpc/` (RPC pillar data)
- `pillar/rpc/common.sls` (shared defaults by layer: `l1`, `l2`, `l3`)

**Overrides**:
Put shared defaults under `rpc_common.l1`, `rpc_common.l2`, and `rpc_common.l3`
in `pillar/rpc/common.sls`, then override on a per‑network basis in
`pillar/rpc/l1*.sls`, `pillar/rpc/l2*.sls`, or `pillar/rpc/l3*.sls`.
The current RPC states are stubs; when automation is added, it should merge
`rpc_common` into the specific layer config (layer values win).

Mainnet placeholders are available:
- `pillar/rpc/l1-mainnet.sls`
- `pillar/rpc/l2-mainnet.sls`
- `pillar/rpc/l3-mainnet.sls`

Mainnet setup uses the same flow as testnet, but with mainnet chain IDs,
endpoints, and snapshots. Copy the testnet examples below and swap in the
mainnet values, or fill in the `*-mainnet.sls` placeholders.

These RPC states are **not** wired into `top.sls`. Apply them explicitly on RPC hosts:
```bash
sudo salt 'rpc-server-01' state.apply rpc.l1
sudo salt 'rpc-server-01' state.apply rpc.l2
sudo salt 'rpc-server-01' state.apply rpc.l3
```

If you want Salt to run Docker Compose upgrades, set `compose_dir` in
`pillar/rpc/common.sls` (or per‑layer overrides in `pillar/rpc/l*.sls`) and run:
```bash
sudo salt 'rpc-server-01' state.apply rpc.upgrade
```
`rpc.l2` and `rpc.l3` also generate `docker-compose.yml` in the configured
`compose_dir` (defaults: `/opt/rpc/l2`, `/opt/rpc/l3`) along with the data dirs.

## Initial Pull / Start / Stop (Salt)

These use the same `compose_dir` values and run only if a compose file exists:
```bash
sudo salt 'rpc-server-01' state.apply rpc.pull
sudo salt 'rpc-server-01' state.apply rpc.start
sudo salt 'rpc-server-01' state.apply rpc.stop
```

## Upgrade (Docker Compose)

When you upgrade RPC images, do a controlled stop/pull/start:

```bash
# L1 (in the L1 compose folder)
docker compose down
docker compose pull
docker compose up -d

# L2 (in the L2 compose folder)
docker compose down
docker compose pull
docker compose up -d

# L3 (in the L3 compose folder)
docker compose down
docker compose pull
docker compose up -d
```

Optional: verify logs after restart
```bash
docker compose logs -fn 200
```

## L1 RPC (GETH & Prysm) — Sepolia

Estimated storage: 1.1–1.5 TB

**Setup**:
```bash
curl -sL https://raw.githubusercontent.com/cerberus-node/aztec-network/refs/heads/main/auto-setup-sepolia.sh -o auto-setup-sepolia.sh && chmod +x auto-setup-sepolia.sh && bash auto-setup-sepolia.sh
```
Choose: **Prysm**

**Verify**:
```bash
curl -s -X POST http://localhost:8545 \
  -H 'Content-Type: application/json' \
  -d '{"jsonrpc":"2.0","method":"eth_syncing","params":[],"id":1}'
```
```bash
curl -s http://localhost:3500/eth/v1/node/syncing | jq
```

**Commands**:
```bash
docker compose up -d
docker compose down
docker compose logs -fn 1000
docker compose logs -fn 1000 geth
docker compose logs -fn 1000 prysm
```

## L2 RPC (Arbitrum Sepolia)

Estimated storage: 1.1–1.5 TB (first setup may need ~2x snapshot space)

**Setup**:
1) Create folders:
```bash
mkdir -p /opt/rpc/l2/arbitrum-sepolia-rpc-data
cd /opt/rpc/l2
```
2) Download snapshot from https://www.publicnode.com/snapshots into `arbitrum-sepolia-rpc-data`.
3) Create `docker-compose.yml`:
```yaml
services:
  arbitrum-sepolia-rpc:
    container_name: arbitrum-sepolia-rpc
    image: offchainlabs/nitro-node:v3.9.3-8bc5554
    user: 0:0
    restart: unless-stopped
    stop_grace_period: 5m
    command:
      --chain.id=421614
      --parent-chain.connection.url=http://geth:8545
      --parent-chain.blob-client.beacon-url=http://prysm:3500
      --http.api=net,web3,eth
      --http.corsdomain=*
      --http.addr=0.0.0.0
      --http.vhosts=*
      --http.port=22557
      --ws.addr 0.0.0.0
      --ws.port=22558
      --ws.origins=*
    volumes:
      - ./arbitrum-sepolia-rpc-data:/root/.arbitrum
    ports:
      - 22557:22557 # json-rpc endpoint
      - 22558:22558 # ws endpoint
    networks:
      - rpc

networks:
  rpc:
    external: true
```

**Commands**:
```bash
docker compose up -d
docker compose down
docker compose logs -fn 1000
```
With Salt (if `compose_dir` is set, default `/opt/rpc/l2`):
```bash
sudo salt 'rpc-server-01' state.apply rpc.pull   # docker compose pull
sudo salt 'rpc-server-01' state.apply rpc.start  # docker compose up -d
sudo salt 'rpc-server-01' state.apply rpc.stop   # docker compose down
```
**Nginx example** (reverse proxy with limits): see block below.

**Nginx (optional)**:
```nginx
upstream backend_sepolia_arb_rpc {
    server 127.0.0.1:22557; #agnc
    #server 209.209.9.159:22557 weight=1 max_fails=10 fail_timeout=30m; #backup-0
    #server 104.152.209.8:22557 weight=1 max_fails=10 fail_timeout=30m; #backup-1
}

server
{
    listen 80;
    listen 443 ssl http2 ;
    server_name sepolia-arb-rpc.agnc.my.id;
    index index.php index.html index.htm default.php default.htm default.html;
    root /www/wwwroot/sepolia-arb-rpc.agnc.my.id;
    include /www/server/panel/vhost/nginx/extension/sepolia-arb-rpc.agnc.my.id/*.conf;
    
    limit_req zone=rpc_limit burst=2000 nodelay;
    limit_conn conn_limit 10000;
    
    #CERT-APPLY-CHECK--START
    include /www/server/panel/vhost/nginx/well-known/sepolia-arb-rpc.agnc.my.id.conf;
    #CERT-APPLY-CHECK--END
    #SSL-START
        ssl_certificate    /www/server/panel/vhost/cert/sepolia-arb-rpc.agnc.my.id/fullchain.pem;
        ssl_certificate_key    /www/server/panel/vhost/cert/sepolia-arb-rpc.agnc.my.id/privkey.pem;
        ssl_protocols TLSv1.1 TLSv1.2 TLSv1.3;
        ssl_ciphers EECDH+CHACHA20:EECDH+CHACHA20-draft:EECDH+AES128:RSA+AES128:EECDH+AES256:RSA+AES256:EECDH+3DES:RSA+3DES:!MD5;
        ssl_prefer_server_ciphers on;
        ssl_session_tickets on;
        ssl_session_cache shared:SSL:10m;
        ssl_session_timeout 10m;
        add_header Strict-Transport-Security "max-age=31536000";
        error_page 497  https://$host$request_uri;
    #SSL-END

    error_page 404 /404.html;
    error_page 502 /502.html;

    location ~ /purge(/.*) {
        proxy_cache_purge cache_one $host$1$is_args$args;
    }
    include /www/server/panel/vhost/nginx/proxy/sepolia-arb-rpc.agnc.my.id/*.conf;

    include enable-php-00.conf;
    include /www/server/panel/vhost/rewrite/sepolia-arb-rpc.agnc.my.id.conf;

    location ~ ^/(\.user.ini|\.htaccess|\.git|\.env|\.svn|\.project|LICENSE|README.md)
    {
        return 404;
    }

    location ~ \.well-known{
        allow all;
    }

    if ( $uri ~ "^/\.well-known/.*\.(php|jsp|py|js|css|lua|ts|go|zip|tar\.gz|rar|7z|sql|bak)$" ) {
        return 403;
    }

    access_log /www/wwwlogs/sepolia-arb-rpc.agnc.my.id.log;
    error_log  /www/wwwlogs/sepolia-arb-rpc.agnc.my.id.error.log;
}
```

```nginx
location ^~ /
{
    proxy_pass http://backend_sepolia_arb_rpc;
    proxy_set_header Host backend_sepolia_arb_rpc;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header REMOTE-HOST $remote_addr;
    proxy_set_header Upgrade $http_upgrade;
    proxy_set_header Connection $connection_upgrade;
    proxy_http_version 1.1;
    add_header X-Cache $upstream_cache_status;
    set $static_filesBL8N6tG 0;
    if ( $uri ~* "\.(gif|png|jpg|css|js|woff|woff2)$" )
    {
        set $static_filesBL8N6tG 1;
        expires 1m;
    }
    if ( $static_filesBL8N6tG = 0 )
    {
        add_header Cache-Control no-cache;
    }
}
```

## L3 RPC (testnet1a)

**Setup**:
1) Create folders:
```bash
mkdir -p /opt/rpc/l3/testnet1a-rpc-data
cd /opt/rpc/l3
```
2) Prepare `testnet1a-rpc-data` (sync data as needed).
3) Create `docker-compose.yml`:
```yaml
services:
  testnet1a-rpc:
    container_name: testnet1a-rpc
    image: offchainlabs/nitro-node:v3.9.4-7f582c3
    user: 0:0
    restart: unless-stopped
    stop_grace_period: 5m
    command:
      --chain.id=18964747554
      --chain.name=COR-0
      --parent-chain.connection.url=http://arbitrum-sepolia-rpc:22557
      --chain.info-json="[{\"chain-id\":18964747554,\"parent-chain-id\":421614,\"parent-chain-is-arbitrum\":true,\"chain-name\":\"COR-0\",\"chain-config\":{\"chainId\":18964747554,\"homesteadBlock\":0,\"daoForkBlock\":null,\"daoForkSupport\":true,\"eip150Block\":0,\"eip150Hash\":\"0x0000000000000000000000000000000000000000000000000000000000000000\",\"eip155Block\":0,\"eip158Block\":0,\"byzantiumBlock\":0,\"constantinopleBlock\":0,\"petersburgBlock\":0,\"istanbulBlock\":0,\"muirGlacierBlock\":0,\"berlinBlock\":0,\"londonBlock\":0,\"clique\":{\"period\":0,\"epoch\":0},\"arbitrum\":{\"EnableArbOS\":true,\"AllowDebugPrecompiles\":false,\"DataAvailabilityCommittee\":true,\"InitialArbOSVersion\":40,\"InitialChainOwner\":\"0xD6b9d395c3368B5412b3a7D2fb0D7327a83Ed792\",\"GenesisBlockNum\":0,\"MaxCodeSize\":24576,\"MaxInitCodeSize\":49152}},\"rollup\":{\"bridge\":\"0x974d0762eBD0883411A75de8BF41a4c7eA93c03d\",\"inbox\":\"0x08a6C4Bbf77A2387D7DDAD41Fd55193467B6e2b6\",\"sequencer-inbox\":\"0xeeF64Fe40F04aB1aB55016A242D4C278721237FD\",\"rollup\":\"0x39F772DfF00756bec951b691778f58d10a753a57\",\"validator-wallet-creator\":\"0x2c37dCBCE3fbe32c9Ba62892F1E41DbB023BB62b\",\"stake-token\":\"0x980B62Da83eFf3D4576C647993b0c1D7faf17c73\",\"deployed-at\":229017936}}]"
      --node.feed.input.url=wss://feed.testnet1a.cortensor.org
      --execution.forwarding-target=https://sequencer.testnet1a.cortensor.org
      --node.data-availability.enable
      --node.data-availability.rest-aggregator.enable
      --node.data-availability.rest-aggregator.online-url-list=https://testnet1a-das-servers.cortensor.org
      --http.api=net,web3,eth,debug
      --http.corsdomain=*
      --http.addr=0.0.0.0
      --http.vhosts=*
      --http.port=10001
      --ws.addr=0.0.0.0
      --ws.port=10002
      --ws.origins=*
    volumes:
      - ./testnet1a-rpc-data:/root/.arbitrum
    ports:
      - 10001:10001 # JSON-RPC endpoint
      - 10002:10002 # WebSocket endpoint
    networks:
      - rpc

networks:
  rpc:
    external: true
```

**Commands**:
```bash
docker compose up -d
docker compose down
docker compose logs -fn 100
```
With Salt (if `compose_dir` is set, default `/opt/rpc/l3`):
```bash
sudo salt 'rpc-server-01' state.apply rpc.pull   # docker compose pull
sudo salt 'rpc-server-01' state.apply rpc.start  # docker compose up -d
sudo salt 'rpc-server-01' state.apply rpc.stop   # docker compose down
```

## Nginx RPC Reverse Proxy (L2 example)

Main server block:
```nginx
upstream backend_sepolia_arb_rpc {
    server 127.0.0.1:22557; #primary
    #server 209.209.9.159:22557 weight=1 max_fails=10 fail_timeout=30m; #backup-0
    #server 104.152.209.8:22557 weight=1 max_fails=10 fail_timeout=30m; #backup-1
}

server {
    listen 80;
    listen 443 ssl http2;
    server_name sepolia-arb-rpc.example.com;
    root /www/wwwroot/sepolia-arb-rpc.example.com;
    include /www/server/panel/vhost/nginx/extension/sepolia-arb-rpc.example.com/*.conf;

    limit_req zone=rpc_limit burst=2000 nodelay;
    limit_conn conn_limit 10000;

    # SSL certificate paths
    ssl_certificate    /www/server/panel/vhost/cert/sepolia-arb-rpc.example.com/fullchain.pem;
    ssl_certificate_key /www/server/panel/vhost/cert/sepolia-arb-rpc.example.com/privkey.pem;
    ssl_protocols TLSv1.1 TLSv1.2 TLSv1.3;
    ssl_ciphers EECDH+CHACHA20:EECDH+AES128:RSA+AES128:EECDH+AES256:RSA+AES256:EECDH+3DES:RSA+3DES:!MD5;
    ssl_prefer_server_ciphers on;
    ssl_session_cache shared:SSL:10m;
    ssl_session_timeout 10m;
    add_header Strict-Transport-Security "max-age=31536000";
    error_page 497 https://$host$request_uri;

    error_page 404 /404.html;
    error_page 502 /502.html;

    location ~ /purge(/.*) {
        proxy_cache_purge cache_one $host$1$is_args$args;
    }
    include /www/server/panel/vhost/nginx/proxy/sepolia-arb-rpc.example.com/*.conf;
    include enable-php-00.conf;
    include /www/server/panel/vhost/rewrite/sepolia-arb-rpc.example.com.conf;

    location ~ ^/(\\.user.ini|\\.htaccess|\\.git|\\.env|\\.svn|\\.project|LICENSE|README.md) { return 404; }
    location ~ \\.well-known { allow all; }

    if ( $uri ~ "^/\\.well-known/.*\\.(php|jsp|py|js|css|lua|ts|go|zip|tar\\.gz|rar|7z|sql|bak)$" ) { return 403; }

    access_log /www/wwwlogs/sepolia-arb-rpc.example.com.log;
    error_log  /www/wwwlogs/sepolia-arb-rpc.example.com.error.log;
}
```

Proxy block:
```nginx
location ^~ / {
    proxy_pass http://backend_sepolia_arb_rpc;
    proxy_set_header Host backend_sepolia_arb_rpc;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header REMOTE-HOST $remote_addr;
    proxy_set_header Upgrade $http_upgrade;
    proxy_set_header Connection $connection_upgrade;
    proxy_http_version 1.1;
    add_header X-Cache $upstream_cache_status;
    set $static_files 0;
    if ( $uri ~* "\\.(gif|png|jpg|css|js|woff|woff2)$" ) { set $static_files 1; expires 1m; }
    if ( $static_files = 0 ) { add_header Cache-Control no-cache; }
}
```

**Nginx (optional)**:
```nginx
limit_req_zone $binary_remote_addr zone=rpc_limit:50m rate=5000r/s;
limit_conn_zone $binary_remote_addr zone=conn_limit:50m;

server
{
    listen 80;
    listen 443 ssl http2 ;
    server_name cor-1.testnet-rpc.agnc.my.id;
    index index.php index.html index.htm default.php default.htm default.html;
    root /www/wwwroot/cor-1.testnet-rpc.agnc.my.id;
    include /www/server/panel/vhost/nginx/extension/cor-1.testnet-rpc.agnc.my.id/*.conf;
    
    limit_req zone=rpc_limit burst=2000 nodelay;
    limit_conn conn_limit 10000;

    #CERT-APPLY-CHECK--START
    include /www/server/panel/vhost/nginx/well-known/cor-1.testnet-rpc.agnc.my.id.conf;
    #CERT-APPLY-CHECK--END
    #SSL-START
        ssl_certificate    /www/server/panel/vhost/cert/cor-1.testnet-rpc.agnc.my.id/fullchain.pem;
        ssl_certificate_key    /www/server/panel/vhost/cert/cor-1.testnet-rpc.agnc.my.id/privkey.pem;
        ssl_protocols TLSv1.1 TLSv1.2 TLSv1.3;
        ssl_ciphers EECDH+CHACHA20:EECDH+CHACHA20-draft:EECDH+AES128:RSA+AES128:EECDH+AES256:RSA+AES256:EECDH+3DES:RSA+3DES:!MD5;
        ssl_prefer_server_ciphers on;
        ssl_session_tickets on;
        ssl_session_cache shared:SSL:10m;
        ssl_session_timeout 10m;
        add_header Strict-Transport-Security "max-age=31536000";
        error_page 497  https://$host$request_uri;
    #SSL-END

    #ERROR-PAGE-START
    error_page 404 /404.html;
    error_page 502 /502.html;
    #ERROR-PAGE-END

    #PHP-INFO-START
    #Clear cache

    location ~ /purge(/.*) {
        proxy_cache_purge cache_one $host$1$is_args$args;
    }
    include /www/server/panel/vhost/nginx/proxy/cor-1.testnet-rpc.agnc.my.id/*.conf;

    include enable-php-00.conf;

    #REWRITE-START
    include /www/server/panel/vhost/rewrite/cor-1.testnet-rpc.agnc.my.id.conf;
    #REWRITE-END

    location ~ ^/(\.user.ini|\.htaccess|\.git|\.env|\.svn|\.project|LICENSE|README.md)
    {
        return 404;
    }

    location ~ \.well-known{
        allow all;
    }

    if ( $uri ~ "^/\.well-known/.*\.(php|jsp|py|js|css|lua|ts|go|zip|tar\.gz|rar|7z|sql|bak)$" ) {
        return 403;
    }

    access_log  /www/wwwlogs/cor-1.testnet-rpc.agnc.my.id.log;
    error_log  /www/wwwlogs/cor-1.testnet-rpc.agnc.my.id.error.log;
}
```

```nginx
location ^~ /
{
    proxy_pass http://localhost:20001;
    proxy_set_header Host localhost;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header REMOTE-HOST $remote_addr;
    proxy_set_header Upgrade $http_upgrade;
    proxy_set_header Connection $connection_upgrade;
    proxy_http_version 1.1;
    add_header X-Cache $upstream_cache_status;
    set $static_fileK370sGqr 0;
    if ( $uri ~* "\.(gif|png|jpg|css|js|woff|woff2)$" )
    {
        set $static_fileK370sGqr 1;
        expires 1m;
    }
    if ( $static_fileK370sGqr = 0 )
    {
        add_header Cache-Control no-cache;
    }
}
```
