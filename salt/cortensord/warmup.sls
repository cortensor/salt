{% set assigned_nodes = pillar.get('cortensord_assigned_nodes', []) %}
{% set config = pillar.get('cortensord', {}) %}
{% set user = config.get('user', 'cortensor') %}
{% set home_dir = config.get('home_dir', '/home/' ~ user) %}
{% set nodes_dir = config.get('nodes_dir', '/opt/cortensor/nodes') %}
{# Set `cortensord:warmup_skip: true` in pillar to skip warmup if done manually #}
{% set warmup_skip = config.get('warmup_skip', False) %}
{# Optional wait controls for warmup #}
{% set warmup_wait_seconds = config.get('warmup_wait_seconds', 0) %}
{% set warmup_wait_timeout = config.get('warmup_wait_timeout', 1800) %}
{% set warmup_wait_for_images = config.get('warmup_wait_for_images', []) %}
{% if warmup_wait_for_images is string %}
  {% set warmup_wait_for_images = [warmup_wait_for_images] %}
{% endif %}

# Only run warmup if there is at least one node assigned
{% if assigned_nodes|length > 0 %}
    # Pick the first node to use for the warmup (Docker cache is shared)
    {% set first_node = assigned_nodes[0] %}

    # Ensure the binary is installed first
    include:
      - .install
      - .config
      - .unit

    {% if warmup_skip %}
    warmup_skipped_marker:
      file.managed:
        - name: /var/lib/cortensor_warmup_done
        - contents: "Warmup skipped on {{ None|strftime('%Y-%m-%d %H:%M:%S') }} (manual run)"
        - replace: False
    {% else %}
    # Start only the first instance to pull Docker images (shared by all nodes)
    cortensord_warmup_instance:
      service.running:
        - name: cortensord@{{ first_node }}
        - enable: True
        - require:
            - file: /etc/systemd/system/cortensord@.service
            - file: {{ nodes_dir }}/{{ first_node }}/.env
        - watch:
            - file: {{ nodes_dir }}/{{ first_node }}/.env

    # Optional wait for images or a fixed delay before marking warmup done
    cortensord_warmup_wait:
      cmd.run:
        - name: |
            /bin/bash -lc 'set -euo pipefail
            source "{{ nodes_dir }}/{{ first_node }}/.env" || true
            IMAGES=({{ warmup_wait_for_images | join(" ") }})
            if [ -z "${IMAGES[*]}" ] && [ -n "${LLM_CONTAINER_IMAGE:-}" ]; then
              IMAGES=("$LLM_CONTAINER_IMAGE")
            fi
            if [ -n "${IMAGES[*]}" ]; then
              for img in "${IMAGES[@]}"; do
                echo "Waiting for Docker image: $img"
                timeout {{ warmup_wait_timeout }} bash -lc "until docker image inspect \"$img\" >/dev/null 2>&1; do sleep 5; done"
              done
            elif [ {{ warmup_wait_seconds }} -gt 0 ]; then
              echo "No image list configured; sleeping {{ warmup_wait_seconds }}s"
              sleep {{ warmup_wait_seconds }}
            else
              echo "No warmup wait configured; continuing"
            fi'
        - require:
            - service: cortensord_warmup_instance

    mark_warmup_done:
      file.managed:
        - name: /var/lib/cortensor_warmup_done
        - contents: "Warmup completed on {{ None|strftime('%Y-%m-%d %H:%M:%S') }}"
        - require:
            - cmd: cortensord_warmup_wait
    {% endif %}

{% endif %}
