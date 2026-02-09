{# Pull RPC docker images (docker compose pull) #}
{% set common = pillar.get('rpc_common', {}) %}
{% set l1 = pillar.get('rpc_l1', {}) %}
{% set l2 = pillar.get('rpc_l2', {}) %}
{% set l3 = pillar.get('rpc_l3', {}) %}

{% set l1_dir = l1.get('compose_dir', common.get('l1', {}).get('compose_dir', '')) %}
{% set l2_dir = l2.get('compose_dir', common.get('l2', {}).get('compose_dir', '')) %}
{% set l3_dir = l3.get('compose_dir', common.get('l3', {}).get('compose_dir', '')) %}

{% macro pull_compose(name, dir) -%}
{% if dir %}
{{ name }}:
  cmd.run:
    - name: |
        /bin/bash -lc 'set -euo pipefail
        docker compose pull'
    - cwd: {{ dir }}
    - onlyif: test -f {{ dir }}/docker-compose.yml -o -f {{ dir }}/compose.yml
{%- endif %}
{%- endmacro %}

{{ pull_compose('rpc_l1_pull', l1_dir) }}
{{ pull_compose('rpc_l2_pull', l2_dir) }}
{{ pull_compose('rpc_l3_pull', l3_dir) }}
