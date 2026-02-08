# ==============================================================================
# Cortensor Node Registry
# ==============================================================================
# This file defines the configuration for EVERY node in the fleet.
# Determining WHICH server runs WHICH node is done in `pillar/cortensord/server_*.sls`.
#
# Available Variables (and their defaults):
#
# --- Identity ---
# NODE_PRIVATE_KEY: <Required>
# NODE_PUBLIC_KEY:  "0x00..."
#
# --- Networking ---
# LLM_WORKER_BASE_PORT: 8090
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
# --- Docker ---
# AGENT_MINER_DOCKER_LLM: 1
# LLM_CONTAINER_IMAGE:    "" (Custom image)
#
# --- Blockchain Overrides (Optional) ---
# CONTRACT_ADDRESS_RUNTIME: "..."
# CHAINID: 421614
#
#For a full list of variables, see `salt/cortensord/files/cortensord.env.j2`
# ==============================================================================

cortensord_nodes:
  # --- Server A Nodes ---
  node_01:
    NODE_PRIVATE_KEY: "0xAAA...111"
    LLM_WORKER_BASE_PORT: 8090
    WS_PORT_ROUTER: 9001
    
  node_02:
    NODE_PRIVATE_KEY: "0xAAA...222"
    LLM_WORKER_BASE_PORT: 8091
    WS_PORT_ROUTER: 9002
    LLM_OPTION_GPU: 1
    
  node_03:
    NODE_PRIVATE_KEY: "0xAAA...333"
    LLM_WORKER_BASE_PORT: 8092
    WS_PORT_ROUTER: 9003
    ENABLE_DEDICATED_NODE: 1
    DEDICATED_NODE_AUTHORIZED_SESSIONS: "10,11,12"
    
  node_04:
    NODE_PRIVATE_KEY: "0xAAA...444"
    LLM_WORKER_BASE_PORT: 8093
    WS_PORT_ROUTER: 9004
    LLM_OPTION_CPU_THREADS: 16

  # --- Server B Nodes ---
  node_router_01:
    NODE_PRIVATE_KEY: "0xBBB...111"
    AGENT_ROLE: routerv1
    LLM_WORKER_BASE_PORT: 8090
    WS_PORT_ROUTER: 9001
    
  node_miner_01:
    NODE_PRIVATE_KEY: "0xBBB...222"
    AGENT_ROLE: minerv4
    LLM_WORKER_BASE_PORT: 8091
    WS_PORT_ROUTER: 9002
    
  node_deepseek:
    NODE_PRIVATE_KEY: "0xBBB...333"
    LLM_WORKER_BASE_PORT: 8092
    WS_PORT_ROUTER: 9003
    LLM_CONTAINER_IMAGE: "deepseek-r1:8b-gpu"
    AGENT_MINER_DOCKER_LLM: 1
    
  node_l3_01:
    NODE_PRIVATE_KEY: "0xBBB...444"
    LLM_WORKER_BASE_PORT: 8093
    WS_PORT_ROUTER: 9004
    IS_L3: 1
