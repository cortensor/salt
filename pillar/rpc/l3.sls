# L3 RPC (testnet1a)
# Editable defaults for the docker-compose template.
rpc_l3:
  chain_id: 18964747554
  chain_name: "COR-0"
  rpc_http_port: 10001
  rpc_ws_port: 10002
  image: "offchainlabs/nitro-node:v3.9.4-7f582c3"
  container_name: "testnet1a-rpc"
  parent_http_url: "http://arbitrum-sepolia-rpc:22557"
  feed_ws_url: "wss://feed.testnet1a.cortensor.org"
  sequencer_url: "https://sequencer.testnet1a.cortensor.org"
  da_online_list: "https://testnet1a-das-servers.cortensor.org"
  compose_dir: "/opt/rpc/l3"
  chain_info_json: >-
    [{"chain-id":18964747554,"parent-chain-id":421614,"parent-chain-is-arbitrum":true,"chain-name":"COR-0","chain-config":{"chainId":18964747554,"homesteadBlock":0,"daoForkBlock":null,"daoForkSupport":true,"eip150Block":0,"eip150Hash":"0x0000000000000000000000000000000000000000000000000000000000000000","eip155Block":0,"eip158Block":0,"byzantiumBlock":0,"constantinopleBlock":0,"petersburgBlock":0,"istanbulBlock":0,"muirGlacierBlock":0,"berlinBlock":0,"londonBlock":0,"clique":{"period":0,"epoch":0},"arbitrum":{"EnableArbOS":true,"AllowDebugPrecompiles":false,"DataAvailabilityCommittee":true,"InitialArbOSVersion":40,"InitialChainOwner":"0xD6b9d395c3368B5412b3a7D2fb0D7327a83Ed792","GenesisBlockNum":0,"MaxCodeSize":24576,"MaxInitCodeSize":49152}},"rollup":{"bridge":"0x974d0762eBD0883411A75de8BF41a4c7eA93c03d","inbox":"0x08a6C4Bbf77A2387D7DDAD41Fd55193467B6e2b6","sequencer-inbox":"0xeeF64Fe40F04aB1aB55016A242D4C278721237FD","rollup":"0x39F772DfF00756bec951b691778f58d10a753a57","validator-wallet-creator":"0x2c37dCBCE3fbe32c9Ba62892F1E41DbB023BB62b","stake-token":"0x980B62Da83eFf3D4576C647993b0c1D7faf17c73","deployed-at":229017936}}]
  volumes:
    - "./testnet1a-rpc-data:/root/.arbitrum"
  ports:
    - "10001:10001"
    - "10002:10002"
  networks:
    - "rpc"
  nginx:
    server_name: "cor-1.testnet-rpc.example.com"
    root: "/www/wwwroot/cor-1.testnet-rpc.example.com"
    ssl_certificate: "/www/server/panel/vhost/cert/cor-1.testnet-rpc.example.com/fullchain.pem"
    ssl_certificate_key: "/www/server/panel/vhost/cert/cor-1.testnet-rpc.example.com/privkey.pem"
    access_log: "/www/wwwlogs/cor-1.testnet-rpc.example.com.log"
    error_log: "/www/wwwlogs/cor-1.testnet-rpc.example.com.error.log"
    limit_req_zone: "rpc_limit:50m rate=5000r/s"
    limit_conn_zone: "conn_limit:50m"
    proxy_pass_url: "http://localhost:20001"
    conf_path: "/etc/nginx/conf.d/cor-1-testnet-rpc.conf"
