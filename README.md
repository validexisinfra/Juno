# Juno
Juno is the permissionless neutral home of CosmWasm interoperable smart contracts and the InterWasm DAO. The ecosystem is pioneering CosmWasm development and adoption.

# 🌟 Juno Setup & Upgrade Scripts

A collection of automated scripts for setting up and upgrading Juno nodes on **Mainnet (`juno-1`)**.

---

### ⚙️ Validator Node Setup  
Install a Juno validator node with custom ports, snapshot download, and systemd service configuration.

~~~bash
source <(curl -s https://raw.githubusercontent.com/validexisinfra/Juno/main/installmain.sh)
~~~
---

### 🔄 Validator Node Upgrade 
Upgrade your Juno node binary and safely restart the systemd service.

~~~bash
source <(curl -s https://raw.githubusercontent.com/validexisinfra/Juno/main/upgrademain.sh)
~~~

---

### 🧰 Useful Commands

| Task            | Command                                 |
|-----------------|------------------------------------------|
| View logs       | `journalctl -u junod -f -o cat`        |
| Check status    | `systemctl status junod`              |
| Restart service | `systemctl restart junod`             |
