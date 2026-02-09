# RPC states (L1/L2/L3) live in this folder.
# These are intentionally not wired into the main top.sls by default.
# Apply explicitly on RPC hosts, e.g.: sudo salt 'rpc-server-01' state.apply rpc.l1
# Pillar placeholders are in pillar/rpc/ (testnet + mainnet files).
