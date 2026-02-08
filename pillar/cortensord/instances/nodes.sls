# ==============================================================================
# Cortensor Node Registry (Aggregator)
# ==============================================================================
# This file documents available variables and includes typed registries.
# Determining WHICH server runs WHICH node is done in `pillar/cortensord/servers/*.sls`.
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
# WS_HOST_ROUTER:       "192.168.250.237"  (miners connect to router internal IP)
# WS_PORT_ROUTER:       9001              (miners connect to router internal port; default in common.sls)
# ROUTER_EXTERNAL_IP/PORT are set on router nodes only (public-facing)
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
# For a full list of variables, see `salt/cortensord/files/cortensord.env.j2`
# ==============================================================================

include:
  - .ephemeral
  - .dedicated
  - .router
