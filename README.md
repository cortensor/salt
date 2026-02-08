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
    
    *Example: If you cloned this repo to `/opt/cor/salt`*:
    ```yaml
    file_roots:
      base:
        - /opt/cor/salt/salt

    pillar_roots:
      base:
        - /opt/cor/salt/pillar
    
    # Optional: Override default home derivation if needed
    # home_dir: /home/deploy
    ```
    *Alternatively, symlink the directories to the default locations:*
    ```bash
    sudo ln -s /opt/cor/salt/salt /srv/salt
    sudo ln -s /opt/cor/salt/pillar /srv/pillar
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

    > **Important**: This ID (`miner-server-01`) must match the entry in your `pillar/top.sls` file on the Master. This is how Salt knows which `miner-server-*.sls` configuration to apply to this specific machine.
    >
    > **Example `pillar/top.sls`**:
    > ```yaml
    > base:
    >   'miner-server-01':  # Matches the minion_id
    >     - cortensord.miner-server-01
    > ```

5.  **Restart Minion**:
    ```bash
    systemctl restart salt-minion
    ```

6.  **Accept Key on Master**:
    On the Master server:
    ```bash
    sudo salt-key -A  # Accept all pending keys
    ```

7.  **Verify Connection**:
    On the Master server, ping the minions:
    ```bash
    sudo salt '*' test.ping
    ```
    *Expected Output:*
    ```yaml
    miner-server-01:
        True
    ```

    You can also run a test command:
    ```bash
    sudo salt '*' cmd.run 'uname -a'
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
    # Miner Server 01 - Node 1
    miner-server-01-node-01:
      NODE_PRIVATE_KEY: "0x111..."
      LLM_WORKER_BASE_PORT: 8090
      WS_PORT_ROUTER: 9001
      
    # Miner Server 01 - Node 2
    miner-server-01-node-02:
      NODE_PRIVATE_KEY: "0x222..."
      LLM_WORKER_BASE_PORT: 8091
      WS_PORT_ROUTER: 9002
```

### 3.2 Targeting Specific Minions
If you have multiple physical servers (Minions), you use the `cortensord_assigned_nodes` list in each server's pillar file (`miner-server-01.sls`, `miner-server-02.sls`).

### 3.3 Configuration Hierarchy (Global, Server, Instance)

You can override variables at different levels. The most specific one wins (Instance > Server > Global).

1.  **Server Updates**:
    To change `CHAINID` for *all nodes* on a specific server (e.g., Miner Server 01), edit `pillar/cortensord/miner-server-01.sls`:
    ```yaml
    cortensord:
      # Optional: Override global settings for this server
      CHAINID: 9999
    
    cortensord_assigned_nodes:
        - miner-server-01-node-01
    ```

2.  **Instance Updates**:
    To change `CHAINID` for a *single node*, edit `pillar/cortensord/nodes.sls`:
    ```yaml
    cortensord_nodes:
      miner-server-01-node-01:
        CHAINID: 5555
    ```

## 4. Operations Manual

This section covers all day-to-day operations for managing the fleet.

### 4.1 Deployment & Installation
**Initial Setup (Per Minion)**:
To install Cortensord and all dependencies (Docker, IPFS) on a new server for the first time:

1.  **Configure Pillar**: Ensure `nodes.sls` and `miner-server-*.sls` are set up.
2.  **Run Install**:
    
    *   **Install on ALL Servers**:
        ```bash
        sudo salt '*' state.apply cortensord
        ```
    *   **Install on ONE Specific Server**:
        ```bash
        sudo salt 'miner-server-01' state.apply cortensord
        ```
    *   **Install Sequentially (One by One)**:
        ```bash
        sudo salt 'miner-server-01' state.apply cortensord
        # ... verify ...
        sudo salt 'miner-server-02' state.apply cortensord
        ```
    *This creates users, installs binaries, generates .env files, downloads Docker images (Warmup), and starts services.*

    **Granular Execution (Component by Component)**:
    If you prefer to install dependencies separately first:
    ```bash
    # 1. Install Docker
    sudo salt '*' state.apply docker

    # 2. Install IPFS
    sudo salt '*' state.apply ipfs

    # 3. Install Cortensord (Application & Config)
    sudo salt '*' state.apply cortensord
    ```
    **Note**: The service state requires the warmup marker file
    (`/var/lib/cortensor_warmup_done`), which is created by
    `cortensord.warmup`. Warmup is skipped by default (`warmup_skip: true`)
    and will only create the marker. If you run pieces manually, make sure
    warmup (or the manual flow below) runs before `cortensord.service`.

    **Manual Warmup (Single Instance)**:
    Warmup is **skipped by default** (`warmup_skip: true`). If you want to
    pull Docker images once and then start the rest, run a single instance
    manually and then create the warmup marker.

    1. Start only the first instance (from the minion):
       ```bash
       sudo systemctl stop 'cortensord@*'
       sudo systemctl start cortensord@miner-server-01-node-01
       sudo journalctl -u cortensord@miner-server-01-node-01 -f
       ```
       Or from the master:
       ```bash
       sudo salt 'miner-server-01' service.stop 'cortensord@*'
       sudo salt 'miner-server-01' service.start cortensord@miner-server-01-node-01
       sudo salt 'miner-server-01' cmd.run "journalctl -u cortensord@miner-server-01-node-01 -f"
       ```
    2. When images are pulled, apply warmup to create the marker:
       ```yaml
       # pillar/cortensord/common.sls (or miner-specific pillar)
       cortensord:
         warmup_skip: true
         # Optional: wait helpers (use one)
         # warmup_wait_seconds: 900
         # warmup_wait_for_images:
         #   - my-llm-image:latest
       ```
       ```bash
       sudo salt 'miner-server-01' saltutil.refresh_pillar
       sudo salt 'miner-server-01' state.apply cortensord.warmup -l info
       ```
    3. Start the rest:
       ```bash
       sudo salt 'miner-server-01' service.start 'cortensord@*'
       ```

---

### 4.2 Routine Operations

**Configuration Updates**:
To apply changes to **ALL servers**:
```bash
sudo salt '*' state.apply cortensord
```
To apply changes to **ONE specific server** (e.g., `miner-server-01`):
```bash
sudo salt 'miner-server-01' state.apply cortensord
```

**Sequential Execution (One by One)**:
If you want to update servers one at a time to ensure safety (e.g., checking logs between updates):
```bash
sudo salt 'miner-server-01' state.apply cortensord
# ... verify logs ...
sudo salt 'miner-server-02' state.apply cortensord
```

**Binary Upgrades**:
To upgrade `cortensord` binary on **ALL servers**:
```bash
sudo salt '*' state.apply cortensord.upgrade
```
To upgrade on **ONE specific server**:
```bash
sudo salt 'miner-server-01' state.apply cortensord.upgrade
```

**Service Management**:

*   **Restart ONE specific instance on ONE server**:
    ```bash
    sudo salt 'miner-server-01' service.restart cortensord@miner-server-01-node-01
    ```

*   **Start/Stop ONE specific instance on ONE server**:
    ```bash
    sudo salt 'miner-server-01' service.start cortensord@miner-server-01-node-01
    sudo salt 'miner-server-01' service.stop cortensord@miner-server-01-node-01
    ```

*   **Restart ALL instances on ONE server**:
    ```bash
    sudo salt 'miner-server-01' service.restart 'cortensord@*'
    ```

*   **Restart ONE instance across ALL servers** (e.g. if `node_router` is deployed everywhere):
    ```bash
    sudo salt '*' service.restart cortensord@node_router
    ```

### 4.3 Troubleshooting & Logs

**View Logs (System)**:
```bash
journalctl -u cortensord@miner-server-01-node-01 -f
```

**View Logs (App)**:
```bash
tail -f /var/log/cortensor/cortensord-miner-server-01-node-01.log
```

**Common Errors**:

*   **"Minion did not return. [No response]"**
    This means the Master timed out waiting for the Minion, but the job might still be running.
    
    1.  **Check if job is still running**:
        ```bash
        sudo salt 'miner-server-01' saltutil.running
        ```
    2.  **Retrieve results later (Job Lookup)**:
        If you see a Job ID (e.g., `20260208095135498459`) in the error/log:
        ```bash
        sudo salt-run jobs.lookup_jid 20260208095135498459
        ```

*   **Manual Debug / Step-by-Step Execution**:
    If the main state fails, you can run detailed sub-states with `-l info` logs:
    ```bash
    # 1. Install Binary & Users
    sudo salt 'miner-server-01' state.apply cortensord.install -l info
    
    # 2. Generate Configs (.env)
    sudo salt 'miner-server-01' state.apply cortensord.config -l info
    
    # 3. Pull Docker Images (Warmup)
    sudo salt 'miner-server-01' state.apply cortensord.warmup -l info
    
    # 4. Setup Systemd Services
    sudo salt 'miner-server-01' state.apply cortensord.service -l info
    
    # 5. Setup Log Rotation
    sudo salt 'miner-server-01' state.apply cortensord.logrotate -l info
    ```

### 4.4 Command Cheat Sheet (Useful)

#### Master Commands (Run on Salt Master)
| Action | Command |
| :--- | :--- |
| **List Minions** | `sudo salt-key -L` |
| **Accept Keys** | `sudo salt-key -A` |
| **Ping Minions** | `sudo salt '*' test.ping` |
| **Apply State** | `sudo salt '*' state.apply cortensord` |
| **Upgrade Binary** | `sudo salt '*' state.apply cortensord.upgrade` |
| **Restart Node** | `sudo salt '*' service.restart cortensord@miner-server-01-node-01` |

#### Targeting Examples
-   **Single Server**:
    ```bash
    sudo salt 'miner-server-01' test.ping
    ```
-   **List of Servers** (`-L`):
    ```bash
    sudo salt -L 'miner-server-01,miner-server-02' test.ping
    ```

#### Running Remote Commands (`cmd.run`)
You can execute ANY shell command on your minions from the master:

*   **Check Disk Space**:
    ```bash
    sudo salt '*' cmd.run 'df -h'
    ```
*   **Check Memory**:
    ```bash
    sudo salt 'miner-server-01' cmd.run 'free -m'
    ```
*   **Run Custom Script/Command**:
    ```bash
    sudo salt '*' cmd.run 'ls -la /opt/cortensor'
    ```

### 4.5 Decommissioning & Key Management

**Revoke/Remove a Minion**:
If you decommission a server or need to re-key it:
1.  **Stop Minion service** on the old server (if still live):
    ```bash
    ssh user@miner-server-01 'sudo systemctl stop salt-minion'
    ```
2.  **Delete Key** on Master:
    ```bash
    sudo salt-key -d 'miner-server-01'
    # Press 'y' to confirm
    ```
    *This revokes the server's access. It will need to re-register to connect again.*
