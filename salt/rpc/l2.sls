# L2 RPC (Arbitrum Sepolia) - manage docker-compose file and data dir
{% set common = pillar.get('rpc_common', {}) %}
{% set cfg = pillar.get('rpc_l2', {}) %}
{% set layer_defaults = common.get('l2', {}) %}
{% set compose_dir = cfg.get('compose_dir', layer_defaults.get('compose_dir', '/opt/rpc/l2')) %}
{% set data_dir = cfg.get('data_dir', 'arbitrum-sepolia-rpc-data') %}
{% set full_data_dir = compose_dir ~ '/' ~ data_dir %}

docker_network_rpc:
  cmd.run:
    - name: docker network inspect rpc || docker network create rpc
    - unless: docker network inspect rpc >/dev/null 2>&1

{{ compose_dir }}:
  file.directory:
    - makedirs: True

{{ full_data_dir }}:
  file.directory:
    - makedirs: True

{{ compose_dir }}/docker-compose.yml:
  file.managed:
    - source: salt://rpc/files/docker-compose.l2.yml.j2
    - template: jinja
    - context:
        cfg: {{ cfg }}
    - mode: 644
    - require:
      - file: {{ compose_dir }}
      - cmd: docker_network_rpc
