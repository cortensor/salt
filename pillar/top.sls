base:
  # 1. Apply Shared Global Configuration to ALL minions
  '*':
    - cortensord.common
    - cortensord.nodes  # Everyone gets the full registry (it's safe, they only run what is assigned)

  # 2. Apply Server-Specific Configurations (Nodes, Overrides)
  'miner-server-01':
    - cortensord.miner-server-01

  'miner-server-02':
    - cortensord.miner-server-02
