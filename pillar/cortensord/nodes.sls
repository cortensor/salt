# ==============================================================================
# Cortensor Node Registry
# ==============================================================================
# This file defines the configuration for EVERY node in the fleet.
# Determining WHICH server runs WHICH node is done in `pillar/cortensord/miner-server-*.sls`.
#
# Available Variables (and their defaults):
#
# --- Node Types ---
# Ephemeral (default): no ENABLE_DEDICATED_NODE, no LLM_CONTAINER_IMAGE
# Dedicated: ENABLE_DEDICATED_NODE=1, can set LLM_CONTAINER_IMAGE
# Router: AGENT_ROLE=routerv1 (no dedicated flags)
#
# --- Identity ---
# NODE_PUBLIC_KEY:  <Required>
# NODE_PRIVATE_KEY: <Required>
#
# --- Networking ---
# LLM_WORKER_BASE_PORT: 8090            (unique per instance on the same server)
# LLM_GATEWAY_WORKER_BASE_PORT: 18888   (unique per instance on the same server)
# WS_PORT_ROUTER:       9001
# WS_HOST_ROUTER:       "192.168.250.237"
#
# --- Agent Role ---
# AGENT_ROLE:           "minerv1" (or "routerv1", "validatorv2")
# IS_L3:                0 (Set to 1 for L3 nodes)
#
# --- Resources (CPU/GPU) ---
# LLM_OPTION_GPU:       0 (Set to 1 to enable GPU)
# LLM_GPU_CONTAINER_DEVICE_IDS: "" (e.g. "0,1")
# LLM_OPTION_CPU_THREADS: -1 (Auto)
#
# --- Docker / LLM Worker ---
# DOCKER_LLM_MANAGER: 1
# LLM_WORKER_PORT_PREFIX: 0
# LLM_WORKER_CONTAINER_NAME_PREFIX: ""
# AGENT_MINER_DOCKER_LLM: 1
# LLM_CONTAINER_IMAGE:    "" (Custom image; dedicated nodes only)
#
# --- Dynamic Model Loading ---
# LLM_MEMORY_INDEX_DYNAMIC_LOADING_EXCLUDE_MODEL_INDEXES: "" (e.g. "6,9")
#
# --- Blockchain Overrides (Optional) ---
# CONTRACT_ADDRESS_RUNTIME: "..."
# CHAINID: 421614
#
#For a full list of variables, see `salt/cortensord/files/cortensord.env.j2`
# ==============================================================================

cortensord_nodes:
  # --- Miner Server 01 Nodes (Ephemeral) ---
  miner-server-01-node-01:
    NODE_PUBLIC_KEY: "0x0000000000000000000000000000000000000000"
    NODE_PRIVATE_KEY: "0xAAA...111"
    LLM_WORKER_BASE_PORT: 8090
    LLM_GATEWAY_WORKER_BASE_PORT: 18888
    WS_PORT_ROUTER: 9001
    DOCKER_LLM_MANAGER: 1
    LLM_WORKER_PORT_PREFIX: 0
    LLM_WORKER_CONTAINER_NAME_PREFIX: ""
    # Dynamic Model Loading: exclude model indexes (comma-separated)
    LLM_MEMORY_INDEX_DYNAMIC_LOADING_EXCLUDE_MODEL_INDEXES: ""
    
  miner-server-01-node-02:
    NODE_PUBLIC_KEY: "0x0000000000000000000000000000000000000000"
    NODE_PRIVATE_KEY: "0xAAA...222"
    LLM_WORKER_BASE_PORT: 8091
    LLM_GATEWAY_WORKER_BASE_PORT: 18889
    WS_PORT_ROUTER: 9002
    DOCKER_LLM_MANAGER: 1
    LLM_WORKER_PORT_PREFIX: 0
    LLM_WORKER_CONTAINER_NAME_PREFIX: ""
    LLM_OPTION_GPU: 1
    # Dynamic Model Loading: exclude model indexes (comma-separated)
    LLM_MEMORY_INDEX_DYNAMIC_LOADING_EXCLUDE_MODEL_INDEXES: ""
    
  # --- Miner Server 01 Dedicated Node ---
  miner-server-01-node-03:
    NODE_PUBLIC_KEY: "0x0000000000000000000000000000000000000000"
    NODE_PRIVATE_KEY: "0xAAA...333"
    LLM_WORKER_BASE_PORT: 8092
    LLM_GATEWAY_WORKER_BASE_PORT: 18890
    WS_PORT_ROUTER: 9003
    DOCKER_LLM_MANAGER: 1
    LLM_WORKER_PORT_PREFIX: 0
    LLM_WORKER_CONTAINER_NAME_PREFIX: ""
    ENABLE_DEDICATED_NODE: 1
    DEDICATED_NODE_AUTHORIZED_SESSIONS: "10,11,12"
    
  miner-server-01-node-04:
    NODE_PUBLIC_KEY: "0x0000000000000000000000000000000000000000"
    NODE_PRIVATE_KEY: "0xAAA...444"
    LLM_WORKER_BASE_PORT: 8093
    LLM_GATEWAY_WORKER_BASE_PORT: 18891
    WS_PORT_ROUTER: 9004
    DOCKER_LLM_MANAGER: 1
    LLM_WORKER_PORT_PREFIX: 0
    LLM_WORKER_CONTAINER_NAME_PREFIX: ""
    LLM_OPTION_CPU_THREADS: 16
    # Dynamic Model Loading: exclude model indexes (comma-separated)
    LLM_MEMORY_INDEX_DYNAMIC_LOADING_EXCLUDE_MODEL_INDEXES: ""

  # --- Miner Server 02 Nodes ---
  # Router
  miner-server-02-node-router:
    NODE_PUBLIC_KEY: "0x0000000000000000000000000000000000000000"
    NODE_PRIVATE_KEY: "0xBBB...111"
    AGENT_ROLE: routerv1
    LLM_WORKER_BASE_PORT: 8090
    LLM_GATEWAY_WORKER_BASE_PORT: 18888
    WS_PORT_ROUTER: 9001
    DOCKER_LLM_MANAGER: 1
    LLM_WORKER_PORT_PREFIX: 0
    LLM_WORKER_CONTAINER_NAME_PREFIX: ""
    # Dynamic Model Loading: exclude model indexes (comma-separated)
    LLM_MEMORY_INDEX_DYNAMIC_LOADING_EXCLUDE_MODEL_INDEXES: ""
    
  # Ephemeral
  miner-server-02-node-miner:
    NODE_PUBLIC_KEY: "0x0000000000000000000000000000000000000000"
    NODE_PRIVATE_KEY: "0xBBB...222"
    AGENT_ROLE: minerv4
    LLM_WORKER_BASE_PORT: 8091
    LLM_GATEWAY_WORKER_BASE_PORT: 18889
    WS_PORT_ROUTER: 9002
    DOCKER_LLM_MANAGER: 1
    LLM_WORKER_PORT_PREFIX: 0
    LLM_WORKER_CONTAINER_NAME_PREFIX: ""
    # Dynamic Model Loading: exclude model indexes (comma-separated)
    LLM_MEMORY_INDEX_DYNAMIC_LOADING_EXCLUDE_MODEL_INDEXES: ""
    
  # Ephemeral
  miner-server-02-node-miner-02:
    NODE_PUBLIC_KEY: "0x0000000000000000000000000000000000000000"
    NODE_PRIVATE_KEY: "0xBBB...333"
    LLM_WORKER_BASE_PORT: 8092
    LLM_GATEWAY_WORKER_BASE_PORT: 18890
    WS_PORT_ROUTER: 9003
    DOCKER_LLM_MANAGER: 1
    LLM_WORKER_PORT_PREFIX: 0
    LLM_WORKER_CONTAINER_NAME_PREFIX: ""
    # Dynamic Model Loading: exclude model indexes (comma-separated)
    LLM_MEMORY_INDEX_DYNAMIC_LOADING_EXCLUDE_MODEL_INDEXES: ""
    
  # Ephemeral (L3)
  miner-server-02-node-l3:
    NODE_PUBLIC_KEY: "0x0000000000000000000000000000000000000000"
    NODE_PRIVATE_KEY: "0xBBB...444"
    LLM_WORKER_BASE_PORT: 8093
    LLM_GATEWAY_WORKER_BASE_PORT: 18891
    WS_PORT_ROUTER: 9004
    DOCKER_LLM_MANAGER: 1
    LLM_WORKER_PORT_PREFIX: 0
    LLM_WORKER_CONTAINER_NAME_PREFIX: ""
    IS_L3: 1
    # Dynamic Model Loading: exclude model indexes (comma-separated)
    LLM_MEMORY_INDEX_DYNAMIC_LOADING_EXCLUDE_MODEL_INDEXES: ""

  # --- Miner Server Dedicated 01 Nodes ---
  # Dedicated nodes can be named after the model they pin.
  miner-server-dedicated-01-node-01:
    NODE_PUBLIC_KEY: "0x0000000000000000000000000000000000000000"
    NODE_PRIVATE_KEY: "0xDDD...111"
    LLM_WORKER_BASE_PORT: 8090
    LLM_GATEWAY_WORKER_BASE_PORT: 18888
    WS_PORT_ROUTER: 9001
    DOCKER_LLM_MANAGER: 1
    LLM_WORKER_PORT_PREFIX: 0
    LLM_WORKER_CONTAINER_NAME_PREFIX: ""
    ENABLE_DEDICATED_NODE: 1
    # Dedicated nodes can pin a specific model image
    LLM_CONTAINER_IMAGE: ""
    # Example: "0,1,2,3,4,5"
    DEDICATED_NODE_AUTHORIZED_SESSIONS: "0,1,2,3,4,5"

  # --- Router Server 01 Nodes ---
  router-server-01-node-router:
    NODE_PUBLIC_KEY: "0x0000000000000000000000000000000000000000"
    NODE_PRIVATE_KEY: "0xEEE...111"
    AGENT_ROLE: routerv1
    LLM_WORKER_BASE_PORT: 8090
    LLM_GATEWAY_WORKER_BASE_PORT: 18888
    WS_PORT_ROUTER: 9001
    ROUTER_EXTERNAL_IP: "192.168.250.221"
    ROUTER_EXTERNAL_PORT: "9001"
    ROUTER_REST_BIND_IP: "127.0.0.1"
    ROUTER_REST_BIND_PORT: "5010"
    ROUTER_MCP: 0
    ROUTER_MCP_BIND_IP: "127.0.0.1"
    ROUTER_MCP_BIND_PORT: "8001"
    ROUTER_MCP_SSE: 0
    ROUTER_MCP_SSE_BIND_IP: "127.0.0.1"
    ROUTER_MCP_SSE_BIND_PORT: "8000"
    X402_ROUTER_NODE_ENABLE: 0
    X402_ROUTER_NODE_NETWORK: "base-sepolia"
    X402_ROUTER_NODE_PAY_TO: ""
    X402_ROUTER_NODE_PRICE_DEFAULT: "0.001"
    X402_ROUTER_NODE_PRICE_COMPLETIONS: "0.001"
