{% set assigned_nodes = pillar.get('cortensord_assigned_nodes', []) %}
{% set config = pillar.get('cortensord', {}) %}
{% set user = config.get('user', 'cortensor') %}
{% set home_dir = config.get('home_dir', '/home/' ~ user) %}
{% set cortensor_bin = home_dir ~ '/.cortensor/bin' %}

# Only run warmup if there is at least one node assigned
{% if assigned_nodes|length > 0 %}
    # Pick the first node to use for the warmup (Docker cache is shared)
    {% set first_node = assigned_nodes[0] %}

    # Ensure the binary is installed first
    include:
      - .install
      - .config

    # Run warmup using the first node's environment
    # This pulls necessary Docker images which are then available to ALL nodes
    cortensord_warmup_shared:
      cmd.run:
        - name: {{ cortensor_bin }}/cortensord --warmup
        # Use the .env of the first node so it knows WHICH images to pull (e.g. if custom model)
        - env:
          - HOME: {{ home_dir }}
        - runas: {{ user }}
        # We need to source the env file to get variables like LLM_CONTAINER_IMAGE
        - prepend_path: {{ cortensor_bin }}
        - shell: /bin/bash
        # Just use the .env we generated
        - env_file: /opt/cortensor/nodes/{{ first_node }}/.env
        - require:
            - file: install_binary
            - file: /opt/cortensor/nodes/{{ first_node }}/.env
        # Create a marker file so we don't re-run this every single time state applies
        - unless: test -f /var/lib/cortensor_warmup_done

    mark_warmup_done:
      file.managed:
        - name: /var/lib/cortensor_warmup_done
        - contents: "Warmup completed on {{ None|strftime('%Y-%m-%d %H:%M:%S') }}"
        - require:
            - cmd: cortensord_warmup_shared

{% endif %}
