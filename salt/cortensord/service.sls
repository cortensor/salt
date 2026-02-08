{% set config = pillar.get('cortensord', {}) %}
{% set user = config.get('user', 'cortensor') %}
{% set group = config.get('group', 'cortensor') %}
{% set home_dir = config.get('home_dir', '/home/' ~ user) %}

{% set assigned_nodes = pillar.get('cortensord_assigned_nodes', []) %}

include:
  - .config

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
    - watch_in:
      - module: systemd_reload

systemd_reload:
  module.wait:
    - name: service.systemctl_reload

{# Iterate through ASSIGNED nodes #}
{% for instance_name in assigned_nodes %}

cortensord_service_{{ instance_name }}:
  service.running:
    - name: cortensord@{{ instance_name }}
    - enable: True
    - init_delay: 10
    - watch:
        - file: /opt/cortensor/nodes/{{ instance_name }}/.env
        - file: /etc/systemd/system/cortensord@.service
        - file: install_binary  # Defined in install.sls, triggers restart on binary upgrade
    - require:
        - file: /var/lib/cortensor_warmup_done

{% endfor %}
