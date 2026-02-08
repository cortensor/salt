cortensord:
  # --- Shared Global Configuration ---
  
  # Default System User
  user: deploy
  group: deploy
  home_dir: /home/deploy

  # Blockchain Globals
  CONTRACT_ADDRESS_RUNTIME: "0xa438cE917a5740267e0f7217f81cbbAA23E7e106"
  CHAINID: 421614
  
  # Default Installer URL
  source_url: https://github.com/cortensor/installer.git

  # --- Dependencies Configuration ---
  
  # IPFS Configuration
  ipfs_version: "v0.33.0"
  
  # Docker Configuration
  # Base URL for Docker repo (useful for mirrors or air-gapped environments)
  # Dynamic part (os/arch) will be appended by the state logic
  docker_base_url: "https://download.docker.com/linux"
