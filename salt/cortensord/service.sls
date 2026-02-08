{% set config = pillar.get('cortensord', {}) %}
{% set user = config.get('user', 'cortensor') %}
{% set group = config.get('group', 'cortensor') %}
{% set home_dir = config.get('home_dir', '/home/' ~ user) %}
{% set nodes_dir = config.get('nodes_dir', '/opt/cortensor/nodes') %}

{% set assigned_nodes = pillar.get('cortensord_assigned_nodes', []) %}

include:
  - .config
  - .unit

# Ensure the warmup marker exists before starting services.
/var/lib/cortensor_warmup_done:
  file.exists: []

{# Iterate through ASSIGNED nodes #}
{% for instance_name in assigned_nodes %}

cortensord_service_{{ instance_name }}:
  service.running:
    - name: cortensord@{{ instance_name }}
    - enable: True
    - init_delay: 10
    - watch:
        - file: {{ nodes_dir }}/{{ instance_name }}/.env
        - file: /etc/systemd/system/cortensord@.service
        - file: install_binary  # Defined in install.sls, triggers restart on binary upgrade
    - require:
        - file: /var/lib/cortensor_warmup_done

{% endfor %}
