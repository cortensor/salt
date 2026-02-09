# L2 RPC (Arbitrum Sepolia)
# Editable defaults for the docker-compose template.
rpc_l2:
  chain_id: 421614
  rpc_http_port: 22557
  rpc_ws_port: 22558
  data_dir: "arbitrum-sepolia-rpc-data"
  image: "offchainlabs/nitro-node:v3.9.3-8bc5554"
  container_name: "arbitrum-sepolia-rpc"
  parent_http_url: "http://geth:8545"
  parent_beacon_url: "http://prysm:3500"
  compose_dir: "/opt/rpc/l2"
  volumes:
    - "./arbitrum-sepolia-rpc-data:/root/.arbitrum"
  ports:
    - "22557:22557"
    - "22558:22558"
  networks:
    - "rpc"
  nginx:
    server_name: "sepolia-arb-rpc.example.com"
    root: "/www/wwwroot/sepolia-arb-rpc.example.com"
    ssl_certificate: "/www/server/panel/vhost/cert/sepolia-arb-rpc.example.com/fullchain.pem"
    ssl_certificate_key: "/www/server/panel/vhost/cert/sepolia-arb-rpc.example.com/privkey.pem"
    access_log: "/www/wwwlogs/sepolia-arb-rpc.example.com.log"
    error_log: "/www/wwwlogs/sepolia-arb-rpc.example.com.error.log"
    limit_req_zone: "rpc_limit:50m rate=5000r/s"
    limit_conn_zone: "conn_limit:50m"
    upstreams:
      - "127.0.0.1:22557"
