base:
  # 1. Apply Shared Global Configuration to ALL minions
  '*':
    - cortensord.common
    - cortensord.nodes  # Everyone gets the full registry (it's safe, they only run what is assigned)

  # 2. Apply Server-Specific Configurations (Nodes, Overrides)
  'minion-id-01':
    - cortensord.server_a

  'minion-id-02':
    - cortensord.server_b
