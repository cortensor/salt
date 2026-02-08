{% set config = pillar.get('cortensord', {}) %}

include:
  - .install
  - .service

# Force update the repo to get newest binary
upgrade_installer_repo:
  git.latest:
    - name: {{ config.get('source_url', 'https://github.com/cortensor/installer.git') }}
    - target: /opt/cortensor-installer
    - force_reset: True
    - update_head: True
    - require_in:
      - file: install_binary  # Defined in install.sls

# Explicitly notify service to restart if we updated the binary
# (Already handled by watch in service.sls, but good to be explicit about dependencies)
