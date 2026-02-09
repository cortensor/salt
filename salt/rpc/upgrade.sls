{# Upgrade RPC docker-compose stacks (down -> pull -> up -d) #}
{% set common = pillar.get('rpc_common', {}) %}
{% set l1 = pillar.get('rpc_l1', {}) %}
{% set l2 = pillar.get('rpc_l2', {}) %}
{% set l3 = pillar.get('rpc_l3', {}) %}

{% set l1_dir = l1.get('compose_dir', common.get('l1', {}).get('compose_dir', '')) %}
{% set l2_dir = l2.get('compose_dir', common.get('l2', {}).get('compose_dir', '')) %}
{% set l3_dir = l3.get('compose_dir', common.get('l3', {}).get('compose_dir', '')) %}

{% macro upgrade_compose(name, dir) -%}
{% if dir %}
{{ name }}:
  cmd.run:
    - name: |
        /bin/bash -lc 'set -euo pipefail
        docker compose down
        docker compose pull
        docker compose up -d'
    - cwd: {{ dir }}
    - onlyif: test -f {{ dir }}/docker-compose.yml -o -f {{ dir }}/compose.yml
{%- endif %}
{%- endmacro %}

{{ upgrade_compose('rpc_l1_upgrade', l1_dir) }}
{{ upgrade_compose('rpc_l2_upgrade', l2_dir) }}
{{ upgrade_compose('rpc_l3_upgrade', l3_dir) }}
