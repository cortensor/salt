{% set config = pillar.get('cortensord', {}) %}
{% set user = config.get('user', 'cortensor') %}
{% set group = config.get('group', 'cortensor') %}
{% set home_dir = config.get('home_dir', '/home/' ~ user) %}
{% set cortensor_bin = home_dir ~ '/.cortensor/bin' %}
{% set cortensor_logs = home_dir ~ '/.cortensor/logs' %}

include:
  - docker
  - ipfs

# 1. User & Group Setup
cortensor_group:
  group.present:
    - name: {{ group }}

cortensor_user:
  user.present:
    - name: {{ user }}
    - gid: {{ group }}
    - home: {{ home_dir }}
    - shell: /bin/bash
    - groups:
      - docker
    - require:
      - group: cortensor_group
      - pkg: docker_install  # defined in docker/init.sls

# 2. Get Installer Repo (contains binary in dist/)
installer_repo:
  git.latest:
    - name: {{ config.get('source_url', 'https://github.com/cortensor/installer.git') }}
    - target: /opt/cortensor-installer
    - force_reset: False
    - update_head: False  # Only clone if missing, do not auto-update

# 3. Upgrade/Install Binary
# Copies binary to /usr/local/bin. If source changes (git pull), this updates.
install_binary:
  file.managed:
    - name: /usr/local/bin/cortensord
    - source: /opt/cortensor-installer/dist/cortensord
    - mode: 755
    - require:
      - git: installer_repo
    # Trigger a restart if binary changes (watched by service state)

# 4. Helper Scripts & Directories
{{ cortensor_bin }}:
  file.directory:
    - user: {{ user }}
    - group: {{ group }}
    - makedirs: True

link_binary_local:
  file.symlink:
    - name: {{ cortensor_bin }}/cortensord
    - target: /usr/local/bin/cortensord
    - user: {{ user }}
    - require:
      - file: install_binary
      - file: {{ cortensor_bin }}

install_start_script:
  file.managed:
    - name: {{ cortensor_bin }}/start-cortensor.sh
    - source: /opt/cortensor-installer/utils/start-linux.sh
    - mode: 755
    - user: {{ user }}
    - group: {{ group }}
    - require:
      - git: installer_repo

install_stop_script:
  file.managed:
    - name: {{ cortensor_bin }}/stop-cortensor.sh
    - source: /opt/cortensor-installer/utils/stop-linux.sh
    - mode: 755
    - user: {{ user }}
    - group: {{ group }}
    - require:
      - git: installer_repo

# 5. Log Dirs (User script did this, we confirm it here)
{{ cortensor_logs }}:
  file.directory:
    - user: {{ user }}
    - group: {{ group }}
    - makedirs: True

log_files:
  file.touch:
    - names:
      - {{ cortensor_logs }}/cortensord.log
      - {{ cortensor_logs }}/cortensord-llm.log
    - makedirs: True
    - require:
        - file: {{ cortensor_logs }}

set_log_perms:
  file.managed:
    - names:
      - {{ cortensor_logs }}/cortensord.log
      - {{ cortensor_logs }}/cortensord-llm.log
    - user: {{ user }}
    - group: {{ group }}
    - replace: False  # Don't overwrite content, just set perms
