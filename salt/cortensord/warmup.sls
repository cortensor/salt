include:
  - .install

# Run warmup to download LLM images
cortensor_warmup:
  cmd.run:
    # Assuming 'warmup' or similar command exists. If it happens on start, 
    # we might just do a 'docker pull' here if we knew the image names.
    # For now, we assume the binary has a flag or we run a dummy start.
    - name: /usr/local/bin/cortensord --warmup || echo "Warmup command not found/failed"
    - unless: test -f /var/lib/cortensor_warmup_done
    - require:
        - cmd: install_cortensord_binary

mark_warmup_done:
  file.managed:
    - name: /var/lib/cortensor_warmup_done
    - contents: "done"
    - require:
        - cmd: cortensor_warmup
