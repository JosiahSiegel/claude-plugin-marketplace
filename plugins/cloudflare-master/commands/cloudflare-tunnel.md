---
name: cloudflare-tunnel
description: Create and configure a Cloudflare Tunnel for Zero Trust access
arguments:
  - name: name
    description: Tunnel name (lowercase, hyphens only)
    required: true
  - name: service
    description: "Local service to expose (e.g., http://localhost:3000)"
    required: true
  - name: hostname
    description: Public hostname (e.g., app.example.com)
    required: true
---

# Create Cloudflare Tunnel

Set up a Cloudflare Tunnel to securely expose local services without opening firewall ports.

## Instructions

1. **Parse arguments**:
   - `name`: Tunnel identifier
   - `service`: Local service URL
   - `hostname`: Public domain to route traffic

2. **Check cloudflared installation**:
   ```bash
   # Check if installed
   cloudflared --version

   # Install if needed (provide platform-specific instructions)
   ```

3. **Authenticate with Cloudflare**:
   ```bash
   cloudflared tunnel login
   # Opens browser for authentication
   # Saves cert to ~/.cloudflared/cert.pem
   ```

4. **Create the tunnel**:
   ```bash
   cloudflared tunnel create {name}
   # Creates credentials file: ~/.cloudflared/<TUNNEL_ID>.json
   ```

5. **Configure DNS routing**:
   ```bash
   cloudflared tunnel route dns {name} {hostname}
   ```

6. **Generate configuration file**:

   Create `~/.cloudflared/config.yml`:

   ```yaml
   tunnel: <TUNNEL_ID>
   credentials-file: /path/to/.cloudflared/<TUNNEL_ID>.json

   ingress:
     - hostname: {hostname}
       service: {service}
     - service: http_status:404
   ```

7. **Run the tunnel**:
   ```bash
   # Foreground (for testing)
   cloudflared tunnel run {name}

   # Install as service (production)
   sudo cloudflared service install
   sudo systemctl enable cloudflared
   sudo systemctl start cloudflared
   ```

## Example Output

For `/cloudflare-tunnel my-app http://localhost:3000 app.example.com`:

### Installation Commands

```bash
# 1. Create tunnel
cloudflared tunnel create my-app
# Output: Created tunnel my-app with id abc123-def456-...

# 2. Route DNS
cloudflared tunnel route dns my-app app.example.com
# Output: Added CNAME app.example.com -> abc123-def456.cfargotunnel.com

# 3. Run tunnel
cloudflared tunnel run my-app
```

### config.yml

```yaml
tunnel: abc123-def456-789
credentials-file: /home/user/.cloudflared/abc123-def456-789.json

ingress:
  - hostname: app.example.com
    service: http://localhost:3000
    originRequest:
      connectTimeout: 30s
      noTLSVerify: false

  # Catch-all (required)
  - service: http_status:404
```

## Advanced Configuration

### Multiple Services

```yaml
ingress:
  # Web application
  - hostname: app.example.com
    service: http://localhost:3000

  # API server
  - hostname: api.example.com
    service: http://localhost:8080

  # WebSocket support
  - hostname: ws.example.com
    service: ws://localhost:9000

  # SSH access
  - hostname: ssh.example.com
    service: ssh://localhost:22

  # Catch-all
  - service: http_status:404
```

### Path-Based Routing

```yaml
ingress:
  - hostname: example.com
    path: /api/*
    service: http://localhost:8080

  - hostname: example.com
    path: /static/*
    service: http://localhost:3001

  - hostname: example.com
    service: http://localhost:3000

  - service: http_status:404
```

### Origin Settings

```yaml
ingress:
  - hostname: secure.example.com
    service: https://localhost:8443
    originRequest:
      noTLSVerify: true        # Accept self-signed certs
      connectTimeout: 30s
      tlsTimeout: 10s
      httpHostHeader: internal-host
      http2Origin: true
      keepAliveConnections: 100
      keepAliveTimeout: 90s

  - service: http_status:404
```

## Docker Deployment

### docker-compose.yml

```yaml
version: '3'
services:
  cloudflared:
    image: cloudflare/cloudflared:latest
    command: tunnel run
    environment:
      - TUNNEL_TOKEN=${TUNNEL_TOKEN}
    restart: unless-stopped
    network_mode: host
```

### With Tunnel Token (Dashboard-Managed)

```bash
# Get token from Zero Trust Dashboard
# Settings > Tunnels > Create > Get Token

docker run -d \
  --name cloudflared \
  --restart unless-stopped \
  cloudflare/cloudflared:latest \
  tunnel run --token <TUNNEL_TOKEN>
```

## Adding Access Policies

After tunnel is running, protect with Cloudflare Access:

1. Go to Zero Trust Dashboard > Access > Applications
2. Create Self-hosted Application
3. Set Application Domain to `{hostname}`
4. Add Access Policies:

```yaml
# Allow company employees
- name: Company Access
  action: Allow
  include:
    - email_domain: company.com

# Require specific group
- name: Admin Only
  action: Allow
  include:
    - group: administrators
  require:
    - login_method: google-oauth
```

## Troubleshooting

### Check Tunnel Status

```bash
# List tunnels
cloudflared tunnel list

# Get tunnel info
cloudflared tunnel info {name}

# View tunnel metrics
curl http://localhost:2000/metrics
```

### Common Issues

1. **DNS not resolving**:
   ```bash
   dig {hostname}
   # Should show CNAME to cfargotunnel.com
   ```

2. **Connection refused**:
   - Verify local service is running
   - Check service URL in config

3. **Certificate errors**:
   - Run `cloudflared tunnel login` again
   - Check cert.pem exists and is valid

4. **Service not available**:
   - Run with debug logging:
   ```bash
   cloudflared tunnel run {name} --loglevel debug
   ```
