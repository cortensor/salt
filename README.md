# Cortensor Node Management with SaltStack

This repository contains SaltStack states and pillar configuration to manage multiple `cortensord` instances across Linux servers.

## Architecture

-   **Salt Master**: The central server controlling configuration.
-   **Salt Minion**: each physical/VPS server running one or more `cortensord` nodes.
-   **Multi-Instance**: Each Minion can run multiple isolated instances of `cortensord` (e.g., node_01, node_02), managed via systemd.

## 1. Salt Master Setup

On your management server (Master):

1.  **Install Salt Master**:
    ```bash
    curl -o bootstrap-salt.sh -L https://raw.githubusercontent.com/saltstack/salt-bootstrap/develop/bootstrap-salt.sh
    sudo sh bootstrap-salt.sh -P -M
    ```
    *` -P` enables pip installation support if needed, `-M` installs Master.*
2.  **Configure File Roots**:
    Edit `/etc/salt/master` to point to this repository.
    ```yaml
    file_roots:
      base:
        - /path/to/corsalt/salt

    pillar_roots:
      base:
        - /path/to/corsalt/pillar
    home_dir: /home/deploy  # Optional: Override default home derivation
    ```
    *Alternatively, symlink the directories to the default locations:*
    ```bash
    ln -s /path/to/corsalt/salt /srv/salt
    ln -s /path/to/corsalt/pillar /srv/pillar
    ```
3.  **Restart Master**:
    ```bash
    systemctl restart salt-master
    ```

## 2. Server (Minion) Setup

For each new server you want to add to the cluster:

1.  **Create Service User**:
    You can create the user manually or let Salt do it, but we recommend creating it first to set up SSH keys or sudo access.
    Ensure this username matches the `user` setting in `pillar/cortensord/common.sls` (default: `deploy`).

    ```bash
    # Example for 'deploy' user
    sudo adduser deploy
    sudo usermod -aG sudo deploy
    ```

2.  **Install Salt Minion**:
    ```bash
    curl -o bootstrap-salt.sh -L https://raw.githubusercontent.com/saltstack/salt-bootstrap/develop/bootstrap-salt.sh
    sudo sh bootstrap-salt.sh -P
    ```

3.  **Point to Master**:
    Edit `/etc/salt/minion` or create `/etc/salt/minion.d/master.conf`:
    ```yaml
    master: <IP_OF_SALT_MASTER>
    ```

4.  **Set Minion ID**:
    Write the unique server name to `/etc/salt/minion_id` (Preferred):
    ```bash
    echo "miner-server-01" | sudo tee /etc/salt/minion_id
    ```
    *Alternatively, set `id: miner-server-01` in `/etc/salt/minion` config.*

5.  **Restart Minion**:
    ```bash
    systemctl restart salt-minion
    ```

6.  **Accept Key on Master**:
    On the Master server:
    ```bash
    salt-key -A  # Accept all pending keys
    ```


## 3. Configuring Cortensord Instances

The configuration is driven by **Pillar** data. You define global settings and per-instance overrides.

File: `pillar/cortensord/nodes.sls`

### 3.1 Basic Structure
Define generic defaults at the top level, and specific instances under `instances`.

```yaml
cortensord:
  # --- Global Defaults (Apply to all instances) ---
  CONTRACT_ADDRESS_RUNTIME: "0xa43..."
  CHAINID: 421614
  
  # --- Instance Definitions (Registry) ---
  cortensord_nodes:
    # Server A - Node 1
    server_a_node_01:
      NODE_PRIVATE_KEY: "0x111..."
      LLM_WORKER_BASE_PORT: 8090
      WS_PORT_ROUTER: 9001
      
    # Server A - Node 2
    server_a_node_02:
      NODE_PRIVATE_KEY: "0x222..."
      LLM_WORKER_BASE_PORT: 8091
      WS_PORT_ROUTER: 9002
```

### 3.2 Targeting Specific Minions
If you have multiple physical servers (Minions), you use the `cortensord_assigned_nodes` list in each server's pillar file (`server_a.sls`, `server_b.sls`).

### 3.3 Configuration Hierarchy (Global, Server, Instance)

You can override variables at different levels. The most specific one wins (Instance > Server > Global).

1.  **Server Updates**:
    To change `CHAINID` for *all nodes* on a specific server (e.g., Server A), edit `pillar/cortensord/server_a.sls`:
    ```yaml
    cortensord:
      # Optional: Override global settings for this server
      CHAINID: 9999
    
    cortensord_assigned_nodes:
        - server_a_node_01
    ```

2.  **Instance Updates**:
    To change `CHAINID` for a *single node*, edit `pillar/cortensord/nodes.sls`:
    ```yaml
    cortensord_nodes:
      server_a_node_01:
        CHAINID: 5555
    ```

## 4. Operations Manual

This section covers all day-to-day operations for managing the fleet.

### 4.1 Deployment & Installation
**Initial Setup (Per Minion)**:
To install Cortensord and all dependencies (Docker, IPFS) on a new server for the first time:

1.  **Configure Pillar**: Ensure `nodes.sls` and `server_*.sls` are set up.
2.  **Run Install**:
    ```bash
    salt '*' state.apply cortensord
    ```
    *This creates users, installs binaries, generates .env files, downloads Docker images (Warmup), and starts services.*

---

### 4.2 Routine Operations

### 4.2 Routine Operations

**Configuration Updates**:
To apply changes to **ALL servers**:
```bash
salt '*' state.apply cortensord
```
To apply changes to **ONE specific server** (e.g., `server-a`):
```bash
salt 'server-a' state.apply cortensord
```

**Binary Upgrades**:
To upgrade `cortensord` binary on **ALL servers**:
```bash
salt '*' state.apply cortensord.upgrade
```
To upgrade on **ONE specific server**:
```bash
salt 'server-a' state.apply cortensord.upgrade
```

**Service Management**:

*   **Restart ONE specific instance on ONE server**:
    ```bash
    salt 'server_a' service.restart cortensord@server_a_node_01
    ```

*   **Restart ALL instances on ONE server**:
    ```bash
    salt 'server_a' service.restart 'cortensord@*'
    ```

*   **Restart ONE instance across ALL servers** (e.g. if `node_router` is deployed everywhere):
    ```bash
    salt '*' service.restart cortensord@node_router
    ```

### 4.3 Troubleshooting & Logs

**View Logs (System)**:
```bash
journalctl -u cortensord@server_a_node_01 -f
```

**View Logs (App)**:
```bash
tail -f /var/log/cortensor/cortensord-server_a_node_01.log
```

### 4.4 Command Cheat Sheet (Useful)

#### Master Commands (Run on Salt Master)
| Action | Command |
| :--- | :--- |
| **List Minions** | `salt-key -L` |
| **Accept Keys** | `salt-key -A` |
| **Ping Minions** | `salt '*' test.ping` |
| **Apply State** | `salt '*' state.apply cortensord` |
| **Upgrade Binary** | `salt '*' state.apply cortensord.upgrade` |
| **Restart Node** | `salt '*' service.restart cortensord@server_a_node_01` |

#### Targeting
-   **Single Server**: `salt 'server-a' ...`
-   **List**: `salt -L 'server-a,server-b' ...`

### 4.5 Decommissioning & Key Management

**Revoke/Remove a Minion**:
If you decommission a server or need to re-key it:
1.  **Stop Minion service** on the old server (if still live):
    ```bash
    ssh user@server-a 'sudo systemctl stop salt-minion'
    ```
2.  **Delete Key** on Master:
    ```bash
    salt-key -d 'server-a'
    # Press 'y' to confirm
    ```
    *This revokes the server's access. It will need to re-register to connect again.*
