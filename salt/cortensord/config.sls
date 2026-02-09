{% set global_config = pillar.get('cortensord', {}) %}
{% set user = global_config.get('user', 'cortensor') %}
{% set group = global_config.get('group', 'cortensor') %}
{% set nodes_dir = global_config.get('nodes_dir', '/opt/cortensor/nodes') %}
{% set log_dir = global_config.get('log_dir', '/var/log/cortensor') %}

{% set node_registry = pillar.get('cortensord_nodes', {}) %}
{% set assigned_nodes = pillar.get('cortensord_assigned_nodes', []) %}

include:
  - .install
  - .unit

# Create base directory for nodes
{{ nodes_dir }}:
  file.directory:
    - user: {{ user }}
    - group: {{ group }}
    - mode: 755
    - makedirs: True
    - recurse:
      - user
      - group

# Create log directory
{{ log_dir }}:
  file.directory:
    - user: {{ user }}
    - group: {{ group }}
    - mode: 755
    - makedirs: True
    - recurse:
      - user
      - group

{# Iterate through ASSIGNED nodes #}
{% for instance_name in assigned_nodes %}
    {% set env_file_name = '.env-' ~ instance_name %}

    {# Look up instance config from Registry #}
    {% set instance_config = node_registry.get(instance_name, {}) %}
    
    {# Merge global config with instance config #}
    {% set final_config = global_config.copy() %}
    {# Remove internal keys if any exist in global_config to keep env clean #}
    {% do final_config.pop('instances', None) %}
    
    {% do final_config.update(instance_config) %}

    {# Ensure per-instance app log file name unless explicitly set #}
    {% if not final_config.get('LOG_FILE_NAME') %}
        {% do final_config.update({'LOG_FILE_NAME': 'agent_miner-' ~ instance_name ~ '.log'}) %}
    {% endif %}

    {# Logic: Only the first instance acts as the IPFS Server #}
    {% if loop.first %}
        {% do final_config.update({'ENABLE_IPFS_SERVER': '1'}) %}
    {% else %}
        {# Force disable for all subsequent instances #}
        {% do final_config.update({'ENABLE_IPFS_SERVER': '0'}) %}
    {% endif %}

{{ nodes_dir }}/{{ instance_name }}:
  file.directory:
    - user: {{ user }}
    - group: {{ group }}
    - mode: 755
    - require:
      - file: {{ nodes_dir }}

{{ nodes_dir }}/{{ instance_name }}/{{ env_file_name }}:
  file.managed:
    - source: salt://cortensord/files/cortensord.env.j2
    - template: jinja
    - user: {{ user }}
    - group: {{ group }}
    - mode: 600
    - context:
        config: {{ final_config }}
    - require:
      - file: {{ nodes_dir }}/{{ instance_name }}

{{ nodes_dir }}/{{ instance_name }}/.env:
  file.symlink:
    - target: {{ nodes_dir }}/{{ instance_name }}/{{ env_file_name }}
    - force: True
    - require:
      - file: {{ nodes_dir }}/{{ instance_name }}/{{ env_file_name }}

{{ log_dir }}/cortensord-{{ instance_name }}.log:
  file.touch:
    - user: {{ user }}
    - group: {{ group }}
    - mode: 644
    - require:
      - file: {{ log_dir }}

{% endfor %}
