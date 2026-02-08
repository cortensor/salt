{% set config = pillar.get('cortensord', {}) %}
{% set user = config.get('user', 'cortensor') %}
{% set group = config.get('group', 'cortensor') %}

logrotate_pkg:
  pkg.installed:
    - name: logrotate

cortensor_logrotate_config:
  file.managed:
    - name: /etc/logrotate.d/cortensord
    - source: salt://cortensord/files/cortensord.logrotate
    - template: jinja
    - user: root
    - group: root
    - mode: 644
    - context:
        user: {{ user }}
        group: {{ group }}
    - require:
      - pkg: logrotate
