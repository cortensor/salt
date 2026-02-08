{% set config = pillar.get('cortensord', {}) %}
# Default: https://download.docker.com/linux
{% set docker_base = config.get('docker_base_url', 'https://download.docker.com/linux') %}

docker_prereqs:
  pkg.installed:
    - names:
      - ca-certificates
      - curl
      - gnupg

docker_gpg_key:
  file.managed:
    - name: /etc/apt/keyrings/docker.asc
    # Construct GPG URL: e.g. https://download.docker.com/linux/ubuntu/gpg
    - source: {{ docker_base }}/{{ grains['os']|lower }}/gpg
    - skip_verify: True
    - makedirs: True
    - mode: 644

docker_repo:
  pkgrepo.managed:
    - humanname: Docker Repo
    # Construct Repo string
    - name: deb [arch={{ grains['osarch'] }} signed-by=/etc/apt/keyrings/docker.asc] {{ docker_base }}/{{ grains['os']|lower }} {{ grains['oscodename'] }} stable
    - file: /etc/apt/sources.list.d/docker.list
    - clean_file: True
    - require:
      - file: docker_gpg_key

docker_install:
  pkg.installed:
    - names:
      - docker-ce
      - docker-ce-cli
      - containerd.io
      - docker-buildx-plugin
      - docker-compose-plugin
    - require:
      - pkgrepo: docker_repo

docker_service:
  service.running:
    - name: docker
    - enable: True
    - require:
      - pkg: docker_install
