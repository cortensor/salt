{% set config = pillar.get('cortensord', {}) %}
{% set assigned_nodes = pillar.get('cortensord_assigned_nodes', []) %}

include:
  - .install
  - .unit
  - .config

# Stop all assigned instances before upgrading
{% for instance_name in assigned_nodes %}
cortensord_stop_{{ instance_name }}:
  service.dead:
    - name: cortensord@{{ instance_name }}
{% endfor %}

# Force update the repo to get newest binary
upgrade_installer_repo:
  git.latest:
    - name: {{ config.get('source_url', 'https://github.com/cortensor/installer.git') }}
    - target: {{ config.get('installer_dir', '/opt/cortensor-installer') }}
    - force_reset: True
    - update_head: True
    - require_in:
      - file: install_binary  # Defined in install.sls
    {% if assigned_nodes|length > 0 %}
    - require:
      {% for instance_name in assigned_nodes %}
      - service: cortensord_stop_{{ instance_name }}
      {% endfor %}
    {% endif %}

# Start all assigned instances after upgrade
{% for instance_name in assigned_nodes %}
cortensord_start_{{ instance_name }}:
  service.running:
    - name: cortensord@{{ instance_name }}
    - enable: True
    - require:
      - git: upgrade_installer_repo
      - file: /var/lib/cortensor_warmup_done
{% endfor %}
