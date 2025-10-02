# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a SaltStack proof-of-concept that demonstrates infrastructure automation using Salt Master-Minion architecture with Docker containers. The project deploys nginx web servers across multiple minions, all managed via Salt commands from a central master.

## Architecture

- **Infrastructure**: 5 Docker containers (1 Salt Master + 4 Salt Minions)
- **Configuration Management**: SaltStack 3006 for orchestration
- **Automation**: Ansible playbooks for initial setup
- **Application**: Nginx containers deployed on each minion
- **Networking**: Docker bridge network with mapped ports

## Key Commands

### Full Deployment Sequence
```bash
# Start infrastructure
docker-compose up -d

# Run all Ansible playbooks in order
cd ansible
ansible-playbook install-salt-master.yml
ansible-playbook install-salt-minion.yml
ansible-playbook setup-docker-minion.yml
ansible-playbook deploy-nginx-via-salt.yml
```

### Container Management
```bash
# View container status
docker-compose ps

# Restart all containers
docker-compose restart

# Stop and remove everything
docker-compose down -v

# Access containers via SSH
ssh ubuntu@localhost -p 2221  # master1 (password: ubuntu)
ssh ubuntu@localhost -p 2222  # minion1
ssh ubuntu@localhost -p 2223  # minion2
ssh ubuntu@localhost -p 2224  # minion3
ssh ubuntu@localhost -p 2225  # minion4
```

### Salt Operations (from master container)
```bash
# Check minion connectivity
salt '*' test.ping

# Deploy changes to all minions
salt '*' cmd.run 'docker restart nginx-web'

# Target specific minion
salt 'minion1' docker.ps

# Check nginx status on all minions
salt '*' cmd.run 'curl -I localhost:8080'
```

### Testing Nginx Endpoints
```bash
curl http://localhost:8080  # minion1
curl http://localhost:8081  # minion2
curl http://localhost:8082  # minion3
curl http://localhost:8083  # minion4
```

## Project Structure

```
/
├── ansible/                        # Ansible automation playbooks
│   ├── inventory.ini              # Host definitions (masters, minions groups)
│   ├── install-salt-master.yml    # Installs Salt 3006 on master with ubuntu user config
│   ├── install-salt-minion.yml    # Installs Salt minion on all 4 minions
│   ├── setup-docker-minion.yml    # Installs Docker on minions via apt
│   └── deploy-nginx-via-salt.yml  # Uses Salt to deploy nginx with custom HTML
├── docker-compose.yml             # Defines 5 Ubuntu containers with systemd
└── Dockerfile                     # Ubuntu 22.04 with SSH and systemd support
```

## Important Implementation Details

### Salt Configuration
- Version pinned to 3006.* using APT preferences
- Master configured with auto_accept for minion keys
- Ubuntu user has passwordless sudo for salt commands via wrapper scripts in /usr/local/bin

### Ansible Inventory
- Uses `masters` and `minions` groups
- All hosts connect via localhost with different SSH ports (2221-2225)
- Ansible become password configured for sudo operations

### Docker Networking
- Port mapping: minion1:8080, minion2:8081, minion3:8082, minion4:8083
- Containers run with privileged mode for systemd functionality
- Volume mount: /sys/fs/cgroup for proper systemd operation

### Nginx Deployment
- Each minion gets unique HTML with "This is [minion-name]"
- HTML files created via template substitution on master
- Distributed using salt-cp command
- Containers named "nginx-web" on all minions

## Common Issues and Solutions

### Ansible Connection Issues
- Ensure you're in the `ansible/` directory when running playbooks
- Inventory file must be in same directory or specify with `-i`

### Salt Version Mismatch
- Check: `salt --version` should show 3006.x
- Repository configured for stable 3006 branch specifically

### Salt Command Permissions
- Use wrapper scripts that auto-sudo: just type `salt` not `sudo salt`
- Aliases configured in ~/.bashrc for ubuntu user

### Docker in Containers
- Containers run privileged mode for Docker-in-Docker capability
- systemd required for proper service management