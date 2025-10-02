# SaltStack POC with Docker and Nginx

This project demonstrates a complete SaltStack infrastructure using Docker containers, with automated deployment of nginx web servers across multiple minions managed via Salt from a central master.

## Architecture Overview

- **1 Salt Master** (master1) - Central management server
- **4 Salt Minions** (minion1-4) - Managed nodes
- **Docker** - Containerization platform on all nodes
- **Nginx** - Web server deployed on all minions
- **Ansible** - Automation tool for initial setup

Each minion runs an nginx container displaying a unique page showing "This is [minion-name]" on port 8080.

## Prerequisites

### On Host Machine

1. **Docker and Docker Compose**

```bash
# macOS
brew install docker docker-compose

# Ubuntu/Linux
sudo apt update
sudo apt install docker.io docker-compose
```

2. **Ansible**

```bash
# macOS
brew install ansible

# Ubuntu/Linux
sudo apt update && sudo apt install ansible

# Or via pip
pip install ansible
```

## Project Structure

```
salt-stack-poc/
├── docker-compose.yml          # Docker container orchestration
├── Dockerfile                  # Ubuntu container with SSH
├── ansible/
│   ├── inventory.ini          # Ansible inventory
│   ├── ansible.cfg            # Ansible configuration
│   ├── install-salt-master.yml    # Salt master installation
│   ├── install-salt-minion.yml    # Salt minion installation
│   ├── setup-docker-minion.yml    # Docker installation
│   └── deploy-nginx-via-salt.yml  # Nginx deployment via Salt
└── README.md                  # This file
```

## Step-by-Step Setup Instructions

### Step 1: Start Docker Containers

Start all 5 Ubuntu containers (1 master, 4 minions):

```bash
# From project root
docker-compose up -d

# Verify all containers are running
docker ps
```

Expected output: 5 containers running (ubuntu-master1, ubuntu-minion1-4)

### Step 2: Install Salt Master

```bash
cd ansible
ansible-playbook install-salt-master.yml
```

This installs:

- Salt Master (version 3006)
- Salt API, SSH, and Syndic
- Configures passwordless salt commands for ubuntu user

### Step 3: Install Salt Minions

```bash
ansible-playbook install-salt-minion.yml
```

This installs Salt Minion on all 4 minion containers and configures them to connect to master1.

### Step 4: Verify Salt Communication

```bash
# SSH into master
ssh ubuntu@localhost -p 2221
# Password: ubuntu

# Check minion keys (should show 4 accepted keys)
salt-key -L

# Test connectivity
salt '*' test.ping
```

Expected: All 4 minions respond with `True`

### Step 5: Install Docker on All Minions

```bash
# From ansible directory
ansible-playbook setup-docker-minion.yml
```

This installs Docker on all minion containers.

### Step 6: Deploy Nginx via Salt

```bash
ansible-playbook deploy-nginx-via-salt.yml
```

This uses Salt commands from the master to:

- Create custom HTML pages for each minion
- Deploy nginx containers on all minions
- Map port 8080 inside containers to host ports

## Accessing the Applications

After successful deployment, access each minion's nginx:

| Minion  | URL                   | Displays        |
| ------- | --------------------- | --------------- |
| minion1 | http://localhost:8080 | This is minion1 |
| minion2 | http://localhost:8081 | This is minion2 |
| minion3 | http://localhost:8082 | This is minion3 |
| minion4 | http://localhost:8083 | This is minion4 |

## Verification Commands

### From Host Machine

```bash
# Test all nginx endpoints
curl http://localhost:8080  # Should show "This is minion1"
curl http://localhost:8081  # Should show "This is minion2"
curl http://localhost:8082  # Should show "This is minion3"
curl http://localhost:8083  # Should show "This is minion4"
```

### From Salt Master

```bash
# SSH to master
ssh ubuntu@localhost -p 2221

# Check Docker containers on all minions
salt '*' cmd.run 'docker ps'

# Verify nginx is responding
salt '*' cmd.run 'curl -I localhost:8080'

# Check specific content
salt 'minion1' cmd.run 'curl -s localhost:8080 | grep "This is"'
```

## Container Access

### SSH Access

| Container | SSH Command                    | Password |
| --------- | ------------------------------ | -------- |
| master1   | `ssh ubuntu@localhost -p 2221` | ubuntu   |
| minion1   | `ssh ubuntu@localhost -p 2222` | ubuntu   |
| minion2   | `ssh ubuntu@localhost -p 2223` | ubuntu   |
| minion3   | `ssh ubuntu@localhost -p 2224` | ubuntu   |
| minion4   | `ssh ubuntu@localhost -p 2225` | ubuntu   |

### Direct Docker Access

```bash
docker exec -it ubuntu-master1 bash
docker exec -it ubuntu-minion1 bash
# etc...
```

## Common Salt Commands

From the master container:

```bash
# Key management
salt-key -L                    # List all keys
salt-key -A -y                  # Accept all pending keys

# Execution
salt '*' test.ping             # Test connectivity
salt '*' cmd.run 'hostname'    # Run command on all minions
salt 'minion1' cmd.run 'date'  # Run on specific minion

# Service management
salt '*' service.status docker
salt '*' docker.ps             # List Docker containers

# Package management
salt '*' pkg.install htop
salt '*' pkg.list_pkgs
```

## Cleanup

To stop and remove all containers:

```bash
# Stop all containers
docker-compose down

# Remove all containers and volumes
docker-compose down -v

# Remove Docker images
docker rmi $(docker images -q)
```

## Troubleshooting

### Issue: Ansible can't connect to containers

```bash
# Ensure containers are running
docker-compose ps

# Test SSH connectivity
ssh ubuntu@localhost -p 2221
```

### Issue: Salt minions not connecting

```bash
# On master
salt-key -L  # Check if keys appear

# On minion
sudo systemctl status salt-minion
sudo tail -f /var/log/salt/minion
```

### Issue: Nginx not accessible

```bash
# Check if container is running
salt 'minion1' cmd.run 'docker ps'

# Check port binding
salt 'minion1' cmd.run 'docker port nginx-web'

# Check nginx logs
salt 'minion1' cmd.run 'docker logs nginx-web'
```

### Issue: Salt version incorrect

```bash
# Check version
salt --version

# Should show 3006.x
```

## Architecture Diagram

```
       Host Machine
       ├── master1 (port 2221 SSH)
       │   └── Salt Master
       │       └── Manages all minions
       │
       ├── minion1 (port 2222 SSH, 8080 HTTP)
       │   ├── Salt Minion
       │   └── Docker → Nginx Container
       │
       ├── minion2 (port 2223 SSH, 8081 HTTP)
       │   ├── Salt Minion
       │   └── Docker → Nginx Container
       │
       ├── minion3 (port 2224 SSH, 8082 HTTP)
       │   ├── Salt Minion
       │   └── Docker → Nginx Container
       │
       └── minion4 (port 2225 SSH, 8083 HTTP)
           ├── Salt Minion
           └── Docker → Nginx Container
```

## Technologies Used

- **SaltStack 3006** - Configuration management and orchestration
- **Docker** - Container platform
- **Docker Compose** - Multi-container orchestration
- **Ansible** - Infrastructure automation
- **Nginx** - Web server
- **Ubuntu 22.04** - Base OS for containers
