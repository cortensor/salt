docker_prereqs:
  pkg.installed:
    - names:
      - ca-certificates
      - curl
      - gnupg

docker_gpg_key:
  file.managed:
    - name: /etc/apt/keyrings/docker.asc
    - source: https://download.docker.com/linux/{{ grains['os']|lower }}/gpg
    - skip_verify: True
    - makedirs: True
    - mode: 644

docker_repo:
  pkgrepo.managed:
    - humanname: Docker Repo
    - name: deb [arch={{ grains['osarch'] }} signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/{{ grains['os']|lower }} {{ grains['oscodename'] }} stable
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
