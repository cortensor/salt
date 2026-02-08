base:
  # 1. Apply Shared Global Configuration to ALL minions
  '*':
    - cortensord.common
    - cortensord.instances.nodes  # Everyone gets the full registry (it's safe, they only run what is assigned)

  # 2. Apply Server-Specific Configurations (Nodes, Overrides)
  # Steps to add a new server:
  # 1) Create a server file in pillar/cortensord/servers/<minion-id>.sls
  # 2) Assign nodes (names must match keys in instances/*.sls)
  # 3) Add the minion ID block below (must match /etc/salt/minion_id)
  # 4) Refresh pillar: sudo salt '<minion-id>' saltutil.refresh_pillar
  'miner-server-01':
    - cortensord.servers.miner-server-01

  'miner-server-02':
    - cortensord.servers.miner-server-02

  'miner-server-03':
    - cortensord.servers.miner-server-03
