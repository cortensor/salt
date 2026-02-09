{% set cfg = pillar.get('rpc_l2', {}) %}
{% set nginx = cfg.get('nginx', {}) %}
{% set conf_path = nginx.get('conf_path', '/etc/nginx/conf.d/sepolia-arb-rpc.conf') %}

nginx_package:
  pkg.installed:
    - name: nginx

{{ conf_path }}:
  file.managed:
    - source: salt://rpc/files/nginx-l2.conf.j2
    - template: jinja
    - context:
        cfg: {{ cfg }}
        nginx: {{ nginx }}
    - user: root
    - group: root
    - mode: 644
    - require:
      - pkg: nginx_package

nginx_reload_l2:
  service.running:
    - name: nginx
    - enable: True
    - reload: True
    - watch:
      - file: {{ conf_path }}
*** End Patchotta партии to=functions.apply_patchйғур expand to=functions.apply_patchристи we need correct JSON? apply_patch tool expects string not json. I used json accidentally. Need rerun proper apply_patch. Let's redo. In previous we used apply_patch; here I need to provide patch. Let's retry. !*** End Patch is not closed due to error; must redo. Let me re-run apply_patch with proper text. Mgbe. Let's call again. ***!
