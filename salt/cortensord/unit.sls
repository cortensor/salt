{% set config = pillar.get('cortensord', {}) %}
{% set user = config.get('user', 'cortensor') %}
{% set group = config.get('group', 'cortensor') %}
{% set home_dir = config.get('home_dir', '/home/' ~ user) %}
{% set nodes_dir = config.get('nodes_dir', '/opt/cortensor/nodes') %}
{% set log_dir = config.get('log_dir', '/var/log/cortensor') %}

# Deploy the systemd template unit
/etc/systemd/system/cortensord@.service:
  file.managed:
    - source: salt://cortensord/files/cortensord@.service
    - template: jinja
    - user: root
    - group: root
    - mode: 644
    - context:
        user: {{ user }}
        group: {{ group }}
        home_dir: {{ home_dir }}
        nodes_dir: {{ nodes_dir }}
        log_dir: {{ log_dir }}
    - watch_in:
      - module: systemd_reload

systemd_reload:
  module.wait:
    - name: service.systemctl_reload
