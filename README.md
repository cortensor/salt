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
    curl -L https://bootstrap.saltproject.io | sudo sh -s -- -M
    ```
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
    curl -L https://bootstrap.saltproject.io | sudo sh
    ```
2.  **Point to Master**:
    Edit `/etc/salt/minion` or create `/etc/salt/minion.d/master.conf`:
    ```yaml
    master: <IP_OF_SALT_MASTER>
    id: <UNIQUE_SERVER_ID>  # e.g., miner-server-01
    ```
3.  **Restart Minion**:
    ```bash
    systemctl restart salt-minion
    ```
4.  **Accept Key on Master**:
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
  
  # --- Instance Definitions ---
  instances:
    # First Instance
    node_01:
      NODE_PRIVATE_KEY: "0x111..."
      LLM_WORKER_BASE_PORT: 8090
      WS_PORT_ROUTER: 9001
      
    # Second Instance
    node_02:
      NODE_PRIVATE_KEY: "0x222..."
      LLM_WORKER_BASE_PORT: 8091  # Must affect port to avoid conflict
      WS_PORT_ROUTER: 9002
```

### 3.2 Targeting Specific Minions
If you have multiple physical servers (Minions) and they need different configurations, you can use Salt's `top.sls` or `match` inside the pillar.
However, often simpler is to have a pillar file per minion or use map files. 

For a simple setup, you can check the minion ID in the pillar:

```yaml
cortensord:
  instances:
    {% if grains['id'] == 'miner-server-01' %}
    node_01:
      ...
    node_02:
      ...
    {% elif grains['id'] == 'miner-server-02' %}
    node_03:
      ...
    {% endif %}
```

### 3.3 Configuration Hierarchy (Global, Server, Instance)

You can override variables at different levels. The most specific one wins (Instance > Server > Global).

1.  **Server Updates**:
    To change `CHAINID` for *all nodes* on a specific server (e.g., Server A), edit `pillar/cortensord/server_a.sls`:
    ```yaml
    cortensord:
      # Optional: Override global settings for this server
      CHAINID: 9999
    
    cortensord_assigned_nodes: ...
    ```

2.  **Instance Updates**:
    To change `CHAINID` for a *single node* (e.g., `node_01`), edit `pillar/cortensord/nodes.sls`:
    ```yaml
    cortensord_nodes:
      node_01:
        CHAINID: 5555
    ```

```yaml
cortensord:
  instances:
    node_test_01:
      # Override Global Contract for this single node
      CONTRACT_ADDRESS_RUNTIME: "0x123...DevNet"
      CHAINID: 999999
      NODE_PRIVATE_KEY: "..."
```

## 4. Operations Manual

This section covers all day-to-day operations for managing the fleet.

### 4.1 Deployment & Installation
To install Cortensord and all dependencies (Docker, IPFS) on new or existing servers:

1.  **Configure Pillar**: Ensure `nodes.sls` and `server_*.sls` are set up.
2.  **Run Install**:
    ```bash
    salt '*' state.apply cortensord
    ```
    *This creates users, installs binaries, generates .env files, and starts services.*

### 4.2 Upgrading
To upgrade the `cortensord` binary to the latest version from the repo:

1.  **Run Upgrade**:
    ```bash
    salt '*' state.apply cortensord.upgrade
    ```
    *This fetches the latest code, recompiles/installs the binary, and restarts all services.*

### 4.3 Configuration Updates
To update configuration (e.g., change keys, ports, or toggles):

1.  **Edit Pillar**: Modify `nodes.sls` or `server_*.sls`.
2.  **Apply Changes**:
    ```bash
    salt '*' state.apply cortensord
    ```
    *This regenerates `.env` files and restarts services if the config changed.*

### 4.4 Service Management
Managing individual nodes via Systemd (from the Master).

-   **Check Status**:
    ```bash
    salt '*' service.status cortensord@node_01
    ```
-   **Restart a Node**:
    ```bash
    salt '*' service.restart cortensord@node_01
    ```
-   **Stop a Node**:
    ```bash
    salt '*' service.stop cortensord@node_01
    ```
-   **Start a Node**:
    ```bash
    salt '*' service.start cortensord@node_01
    ```

### 4.5 Troubleshooting

#### Generic Troubleshooting
-   **Verify Connectivity**: `salt '*' test.ping`
-   **Check Pillar Data**: `salt '*' pillar.items` (Verify the minion sees the correct config)

#### Logs
Logs are stored on the **Minion** (the server running the node).

-   **System Logs (Systemd)**:
    ```bash
    # Run on Minion
    journalctl -u cortensord@node_01 -f
    ```
-   **Application Logs**:
    Located at: `/var/log/cortensor/`
    -   `cortensord-<node_name>.log`
    -   `cortensord-llm-<node_name>.log`

#### Common Issues
1.  **Service Fails to Start**:
    -   Check permissions: `ls -la /opt/cortensor/nodes`
    -   Check specific error: `journalctl -u cortensord@node_01 -n 50`
2.  **IPFS Conflicts**:
    -   Only ONE node per server should have `ENABLE_IPFS_SERVER=1`. Use `salt/cortensord/config.sls` logic to ensure this (automatically handled).

## 5. Architecture & Best Practices

### Why Systemd?
We strongly recommend using `systemctl` (Systemd) over manual `nohup`, `screen`, or background scripts for production nodes. This SaltStack setup uses Systemd for:
1.  **Auto-Restart**: If the process crashes or the server reboots, Systemd automatically brings it back up.
2.  **Logging**: `journalctl` and standard logs are handled cleanly without manual redirection.
3.  **Resource Limits**: We enforce file descriptor limits (`LimitNOFILE=1000000`) at the service level.
4.  **Consistency**: All instances (`node_01`, `node_02`) are managed identically.

⚠️ **Note**: The installer places manual scripts like `start-cortensor.sh` in `.cortensor/bin`. **Do not use these** for production; they will bypass Systemd and you lose auto-restart capabilities.
