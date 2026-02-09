# Shared RPC defaults (override in l1/l2/l3 as needed)
rpc_common:
  l1:
    docker_network: "rpc"
    data_root: "/opt/rpc"
    compose_dir: "/opt/rpc/l1"
    snapshot_source: "https://www.publicnode.com/snapshots"
    nginx_limit_req_zone: "rpc_limit:50m"
    nginx_limit_req_rate: "5000r/s"
    nginx_limit_conn_zone: "conn_limit:50m"

  l2:
    docker_network: "rpc"
    data_root: "/opt/rpc"
    compose_dir: "/opt/rpc/l2"
    snapshot_source: "https://www.publicnode.com/snapshots"
    nginx_limit_req_zone: "rpc_limit:50m"
    nginx_limit_req_rate: "5000r/s"
    nginx_limit_conn_zone: "conn_limit:50m"

  l3:
    docker_network: "rpc"
    data_root: "/opt/rpc"
    compose_dir: "/opt/rpc/l3"
    snapshot_source: "https://www.publicnode.com/snapshots"
    nginx_limit_req_zone: "rpc_limit:50m"
    nginx_limit_req_rate: "5000r/s"
    nginx_limit_conn_zone: "conn_limit:50m"
