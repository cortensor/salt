{% set config = pillar.get('cortensord', {}) %}
{% set ipfs_version = config.get('ipfs_version', 'v0.33.0') %}
{% set ipfs_pkg = 'kubo_' ~ ipfs_version ~ '_linux-amd64.tar.gz' %}

# Allow overriding the full download URL if needed (e.g. internal mirror)
{% set default_url = 'https://github.com/ipfs/kubo/releases/download/' ~ ipfs_version ~ '/' ~ ipfs_pkg %}
{% set ipfs_url = config.get('ipfs_download_url', default_url) %}

ipfs_download:
  file.managed:
    - name: /opt/{{ ipfs_pkg }}
    - source: {{ ipfs_url }}
    - skip_verify: True
    - mode: 644

ipfs_extract:
  archive.extracted:
    - name: /opt/ipfs_install
    - source: /opt/{{ ipfs_pkg }}
    - enforce_toplevel: False
    - require:
      - file: ipfs_download

# The extracted folder is usually 'kubo'
ipfs_install:
  cmd.run:
    - name: ./install.sh
    - cwd: /opt/ipfs_install/kubo
    - unless: test -x /usr/local/bin/ipfs
    - require:
      - archive: ipfs_extract
