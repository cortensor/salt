{% set ipfs_version = 'v0.33.0' %}
{% set ipfs_pkg = 'kubo_' ~ ipfs_version ~ '_linux-amd64.tar.gz' %}
{% set ipfs_url = 'https://github.com/ipfs/kubo/releases/download/' ~ ipfs_version ~ '/' ~ ipfs_pkg %}

ipfs_download:
  file.managed:
    - name: /opt/{{ ipfs_pkg }}
    - source: {{ ipfs_url }}
    - skip_verify: True  # For speed/simplicity, hash should ideally be added
    - mode: 644

ipfs_extract:
  archive.extracted:
    - name: /opt/ipfs_install
    - source: /opt/{{ ipfs_pkg }}
    - enforce_toplevel: False
    - require:
      - file: ipfs_download

ipfs_install:
  cmd.run:
    - name: ./install.sh
    - cwd: /opt/ipfs_install/kubo
    - unless: test -x /usr/local/bin/ipfs
    - require:
      - archive: ipfs_extract
