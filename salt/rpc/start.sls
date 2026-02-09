{# Start RPC docker-compose stacks (up -d) #}
{% set common = pillar.get('rpc_common', {}) %}
{% set l1 = pillar.get('rpc_l1', {}) %}
{% set l2 = pillar.get('rpc_l2', {}) %}
{% set l3 = pillar.get('rpc_l3', {}) %}

{% set l1_dir = l1.get('compose_dir', common.get('l1', {}).get('compose_dir', '')) %}
{% set l2_dir = l2.get('compose_dir', common.get('l2', {}).get('compose_dir', '')) %}
{% set l3_dir = l3.get('compose_dir', common.get('l3', {}).get('compose_dir', '')) %}

{% macro start_compose(name, dir) -%}
{% if dir %}
{{ name }}:
  cmd.run:
    - name: |
        /bin/bash -lc 'set -euo pipefail
        docker compose up -d'
    - cwd: {{ dir }}
    - onlyif: test -f {{ dir }}/docker-compose.yml -o -f {{ dir }}/compose.yml
{%- endif %}
{%- endmacro %}

{{ start_compose('rpc_l1_start', l1_dir) }}
{{ start_compose('rpc_l2_start', l2_dir) }}
{{ start_compose('rpc_l3_start', l3_dir) }}
