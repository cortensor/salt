{% set config = pillar.get('cortensord', {}) %}
{% set user = config.get('user', 'cortensor') %}
{% set home_dir = config.get('home_dir', '/home/' ~ user) %}
{% set nodes_dir = config.get('nodes_dir', '/opt/cortensor/nodes') %}

# Stop all instances (template units)
stop_cortensord_units:
  cmd.run:
    - name: systemctl stop 'cortensord@*'
    - onlyif: systemctl list-units --type=service --all 'cortensord@*' | grep -q cortensord@

# Remove systemd unit
/etc/systemd/system/cortensord@.service:
  file.absent:
    - require:
      - cmd: stop_cortensord_units

# Reload systemd after removing unit
systemd_reload:
  module.run:
    - name: service.systemctl_reload
    - require:
      - file: /etc/systemd/system/cortensord@.service

# Remove binary and local symlink
/usr/local/bin/cortensord:
  file.absent: []

{{ home_dir }}/.cortensor/bin/cortensord:
  file.absent: []

# Remove all node directories and env files
{{ nodes_dir }}:
  file.absent:
    - require:
      - cmd: stop_cortensord_units
