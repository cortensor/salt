{% set cfg = pillar.get('rpc_l3', {}) %}
{% set nginx = cfg.get('nginx', {}) %}
{% set conf_path = nginx.get('conf_path', '/etc/nginx/conf.d/cor-1-testnet-rpc.conf') %}

nginx_package:
  pkg.installed:
    - name: nginx

{{ conf_path }}:
  file.managed:
    - source: salt://rpc/files/nginx-l3.conf.j2
    - template: jinja
    - context:
        cfg: {{ cfg }}
        nginx: {{ nginx }}
    - user: root
    - group: root
    - mode: 644
    - require:
      - pkg: nginx_package

nginx_reload_l3:
  service.running:
    - name: nginx
    - enable: True
    - reload: True
    - watch:
      - file: {{ conf_path }}
