{% set config = pillar.get('cortensord', {}) %}
{% set user = config.get('user', 'cortensor') %}
{% set group = config.get('group', 'cortensor') %}
{% set home_dir = config.get('home_dir', '/home/' ~ user) %}
{% set installer_dir = config.get('installer_dir', '/opt/cortensor-installer') %}
{% set cortensor_bin = home_dir ~ '/.cortensor/bin' %}

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
git_lfs:
  pkg.installed:
    - name: git-lfs

installer_repo:
  git.latest:
    - name: {{ config.get('source_url', 'https://github.com/cortensor/installer.git') }}
    - target: {{ installer_dir }}
    - force_reset: False
    - update_head: False  # Only clone if missing, do not auto-update
    - require:
      - pkg: git_lfs

installer_repo_lfs_pull:
  cmd.run:
    - name: git lfs pull
    - cwd: {{ installer_dir }}
    - shell: /bin/bash
    - require:
      - git: installer_repo
      - pkg: git_lfs
    # Skip if binary is already a real file (not a Git LFS pointer)
    - unless: test -f {{ installer_dir }}/dist/cortensord && ! head -n 1 {{ installer_dir }}/dist/cortensord | grep -q 'git-lfs'

# 3. Upgrade/Install Binary
# Copies binary to /usr/local/bin. If source changes (git pull), this updates.
install_binary:
  file.managed:
    - name: /usr/local/bin/cortensord
    - source: {{ installer_dir }}/dist/cortensord
    - mode: 755
    - require:
      - git: installer_repo
      - cmd: installer_repo_lfs_pull
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
    - source: {{ installer_dir }}/utils/start-linux.sh
    - mode: 755
    - user: {{ user }}
    - group: {{ group }}
    - require:
      - git: installer_repo

install_stop_script:
  file.managed:
    - name: {{ cortensor_bin }}/stop-cortensor.sh
    - source: {{ installer_dir }}/utils/stop-linux.sh
    - mode: 755
    - user: {{ user }}
    - group: {{ group }}
    - require:
      - git: installer_repo
