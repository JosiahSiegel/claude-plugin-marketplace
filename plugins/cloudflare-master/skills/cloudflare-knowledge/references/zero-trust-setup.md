# Cloudflare Zero Trust Setup Guide

## Overview

Cloudflare Zero Trust is a security platform that replaces traditional VPNs with identity-based access control. It includes:

- **Cloudflare Tunnel**: Expose internal services without opening firewall ports
- **Cloudflare Access**: Identity-aware proxy for application access
- **Cloudflare WARP**: Device client for secure connectivity
- **Gateway**: DNS filtering and web security

---

## Cloudflare Tunnel

### Installation

```bash
# macOS
brew install cloudflared

# Windows
winget install Cloudflare.cloudflared

# Linux (Debian/Ubuntu)
curl -L https://pkg.cloudflare.com/cloudflare-main.gpg | sudo tee /usr/share/keyrings/cloudflare-archive-keyring.gpg >/dev/null
echo "deb [signed-by=/usr/share/keyrings/cloudflare-archive-keyring.gpg] https://pkg.cloudflare.com/cloudflared $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/cloudflared.list
sudo apt update && sudo apt install cloudflared

# Linux (Direct download)
curl -L https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64 -o cloudflared
chmod +x cloudflared
sudo mv cloudflared /usr/local/bin/

# Docker
docker pull cloudflare/cloudflared:latest
```

### Quick Start

```bash
# 1. Login to Cloudflare
cloudflared tunnel login
# Opens browser for authentication
# Saves certificate to ~/.cloudflared/cert.pem

# 2. Create a tunnel
cloudflared tunnel create my-tunnel
# Outputs: Created tunnel my-tunnel with id <TUNNEL_ID>
# Saves credentials to ~/.cloudflared/<TUNNEL_ID>.json

# 3. Create DNS record
cloudflared tunnel route dns my-tunnel app.example.com

# 4. Run the tunnel
cloudflared tunnel run my-tunnel
```

### Configuration File

Create `~/.cloudflared/config.yml`:

```yaml
# Tunnel ID and credentials
tunnel: <TUNNEL_ID>
credentials-file: /home/user/.cloudflared/<TUNNEL_ID>.json

# Ingress rules (processed top to bottom)
ingress:
  # Route specific hostname to service
  - hostname: app.example.com
    service: http://localhost:3000

  # Route with path matching
  - hostname: api.example.com
    path: /v1/*
    service: http://localhost:8080

  # WebSocket support
  - hostname: ws.example.com
    service: ws://localhost:9000

  # TCP service (SSH, database, etc.)
  - hostname: ssh.example.com
    service: ssh://localhost:22

  # With origin configuration
  - hostname: secure.example.com
    service: https://localhost:8443
    originRequest:
      noTLSVerify: true  # Accept self-signed certs
      connectTimeout: 30s
      tlsTimeout: 10s
      httpHostHeader: internal-hostname

  # Catch-all (required, must be last)
  - service: http_status:404
```

### Advanced Configuration

```yaml
tunnel: <TUNNEL_ID>
credentials-file: /path/to/credentials.json

# Logging
loglevel: info
logfile: /var/log/cloudflared.log

# Metrics
metrics: localhost:2000

# Origin settings (global defaults)
originRequest:
  connectTimeout: 30s
  noHappyEyeballs: false
  tcpKeepAlive: 30s
  keepAliveConnections: 100
  keepAliveTimeout: 1m30s
  httpHostHeader: ""
  originServerName: ""
  caPool: ""
  noTLSVerify: false
  disableChunkedEncoding: false
  proxyAddress: 127.0.0.1
  proxyPort: 0
  proxyType: ""
  http2Origin: false

ingress:
  # Load balancing multiple backends
  - hostname: api.example.com
    service: http://localhost:8080
    originRequest:
      noTLSVerify: true

  - hostname: api.example.com
    service: http://localhost:8081  # Failover

  # Health checks
  - hostname: health.example.com
    service: hello_world  # Built-in health endpoint

  - service: http_status:404
```

### Running as a Service

#### Linux (systemd)

```bash
# Install service
sudo cloudflared service install

# Start service
sudo systemctl start cloudflared
sudo systemctl enable cloudflared

# View logs
sudo journalctl -u cloudflared -f
```

#### macOS

```bash
# Install service
sudo cloudflared service install

# Start service
sudo launchctl start com.cloudflare.cloudflared

# View logs
tail -f /var/log/cloudflared.log
```

#### Windows

```powershell
# Install service
cloudflared.exe service install

# Start service
sc start cloudflared
```

#### Docker

```yaml
# docker-compose.yml
version: '3'
services:
  cloudflared:
    image: cloudflare/cloudflared:latest
    command: tunnel run
    environment:
      - TUNNEL_TOKEN=<YOUR_TUNNEL_TOKEN>
    restart: unless-stopped
```

### Tunnel Dashboard Management

Instead of CLI-managed tunnels, you can create tunnels in the Cloudflare dashboard:

1. Go to Zero Trust > Access > Tunnels
2. Create a tunnel
3. Get the tunnel token
4. Run with token:

```bash
cloudflared tunnel run --token <TUNNEL_TOKEN>
```

---

## Cloudflare Access

### Application Setup

In Cloudflare Zero Trust dashboard:

1. Go to Access > Applications
2. Create Application > Self-hosted

```yaml
# Application configuration
name: Internal Dashboard
type: Self-hosted
session_duration: 24h
domain: dashboard.example.com

# Optional: subdomain matching
include_subdomains: true
```

### Access Policies

```yaml
# Policy 1: Allow company emails
name: Company Employees
action: Allow
include:
  - email_domain: company.com

# Policy 2: Require specific group
name: Engineering Team
action: Allow
include:
  - group: engineering
require:
  - login_method: google-oauth

# Policy 3: Block specific IPs
name: Block Bad IPs
action: Block
include:
  - ip: 192.168.1.0/24

# Policy 4: Require device posture
name: Secure Devices Only
action: Allow
include:
  - email_domain: company.com
require:
  - device_posture:
      - serial_number_check
      - disk_encryption
```

### Service Auth (Machine-to-Machine)

For automated access without user authentication:

```yaml
# Service Auth policy
name: CI/CD Access
action: Service Auth
include:
  - service_token: <token_id>
```

Generate service token:
1. Go to Access > Service Auth
2. Create Service Token
3. Use in requests:

```bash
curl -H "CF-Access-Client-Id: <client_id>" \
     -H "CF-Access-Client-Secret: <client_secret>" \
     https://internal-api.example.com/data
```

### JWT Validation in Workers

```typescript
interface Env {
  TEAM_DOMAIN: string;
}

async function validateAccessJWT(request: Request, env: Env): Promise<{ email: string } | null> {
  const jwt = request.headers.get("CF-Access-JWT-Assertion");
  if (!jwt) return null;

  try {
    // Fetch Access public keys
    const certsUrl = `https://${env.TEAM_DOMAIN}/cdn-cgi/access/certs`;
    const certsResponse = await fetch(certsUrl);
    const { public_certs } = await certsResponse.json();

    // Verify JWT (simplified - use proper JWT library)
    const [header, payload, signature] = jwt.split(".");
    const decodedPayload = JSON.parse(atob(payload));

    // Verify claims
    if (decodedPayload.iss !== `https://${env.TEAM_DOMAIN}`) {
      return null;
    }

    if (decodedPayload.exp < Date.now() / 1000) {
      return null;
    }

    return { email: decodedPayload.email };
  } catch {
    return null;
  }
}

export default {
  async fetch(request: Request, env: Env) {
    const user = await validateAccessJWT(request, env);

    if (!user) {
      return new Response("Unauthorized", { status: 401 });
    }

    return new Response(`Hello, ${user.email}!`);
  },
};
```

---

## WARP Client

### Deployment Methods

1. **Manual Installation**
   - Download from https://one.one.one.one
   - Install and configure

2. **MDM Deployment**
   - Download MSI/PKG installers
   - Configure via MDM policy

3. **Gateway Configuration**
   - Download profile from Zero Trust dashboard
   - Distribute to users

### WARP Configuration

```xml
<!-- macOS MDM Profile -->
<dict>
  <key>organization</key>
  <string>your-team-name</string>
  <key>enable</key>
  <true/>
  <key>gateway_unique_id</key>
  <string>your-gateway-id</string>
  <key>service_mode</key>
  <string>warp</string>
  <key>onboarding</key>
  <false/>
</dict>
```

### Split Tunneling

Include/exclude specific IPs or domains from WARP:

```yaml
# In Zero Trust Dashboard > Settings > WARP Client > Split Tunnels

# Exclude mode (default): These bypass WARP
exclude:
  - 10.0.0.0/8      # Internal network
  - 172.16.0.0/12   # Internal network
  - 192.168.0.0/16  # Internal network
  - localhost       # Local development

# Include mode: Only these go through WARP
include:
  - company-api.com
  - 10.100.0.0/16   # Only corporate network
```

### Device Posture Checks

```yaml
# Disk encryption check
- rule_name: Require FileVault
  type: file
  value: true
  platform: macOS

# OS version check
- rule_name: Minimum macOS version
  type: os_version
  operator: >=
  version: "13.0"
  platform: macOS

# Firewall check
- rule_name: Firewall enabled
  type: firewall
  value: true

# Serial number check
- rule_name: Company devices only
  type: serial_number
  value:
    - ABC123
    - DEF456
```

---

## Gateway (DNS Filtering)

### DNS Policies

```yaml
# Block malware
- name: Block Malware
  action: Block
  traffic: dns
  selector: Security Risks
    - Malware
    - Phishing
    - Spam

# Block social media
- name: Block Social Media
  action: Block
  traffic: dns
  selector: Content Categories
    - Social Networks

# Allow specific domains
- name: Allow Company Domains
  action: Allow
  traffic: dns
  selector: Domain
    - "*.company.com"

# Custom block
- name: Block Gaming
  action: Block
  traffic: dns
  selector: Domain
    - "*.steam.com"
    - "*.epicgames.com"
```

### HTTP Policies

```yaml
# Block file uploads
- name: Block Uploads
  action: Block
  traffic: http
  selector: Upload Mime Type
    - application/zip
    - application/x-rar

# Inspect SSL
- name: Inspect Traffic
  action: Do Not Inspect
  traffic: http
  selector: Domain
    - "*.banking.com"  # Don't inspect banking
```

---

## Troubleshooting

### Tunnel Issues

```bash
# Check tunnel status
cloudflared tunnel info my-tunnel

# Test connectivity
cloudflared tunnel run my-tunnel --loglevel debug

# Verify DNS
dig app.example.com

# Check credentials
ls -la ~/.cloudflared/
```

### Access Issues

```bash
# Test Access policy
curl -I https://app.example.com

# Check JWT
curl -H "Cookie: CF_Authorization=<jwt>" https://app.example.com

# Verify identity
curl https://your-team.cloudflareaccess.com/cdn-cgi/access/get-identity
```

### WARP Issues

```bash
# Check WARP status
warp-cli status

# Reconnect
warp-cli disconnect && warp-cli connect

# Reset registration
warp-cli registration delete
warp-cli register
```

---

## Architecture Diagrams

### Basic Tunnel Setup

```
[User]
   |
   v
[Cloudflare Edge]
   |
   v (Tunnel connection, outbound only)
[cloudflared] --> [Internal Service]
                      localhost:3000
```

### Zero Trust Architecture

```
[Remote User with WARP]
   |
   v
[Cloudflare Edge]
   |
   +-- [Gateway: DNS/HTTP Filtering]
   |
   +-- [Access: Identity Check]
         |
         v (If authorized)
   [Tunnel] --> [Internal Apps]
```

### Multiple Services

```
                    [Cloudflare Edge]
                          |
                          v
                    [cloudflared]
                          |
    +---------------------+---------------------+
    |                     |                     |
    v                     v                     v
[Web App]           [API Server]          [Database]
:3000               :8080                 :5432
```

---

## Best Practices

### Security

1. **Use Access policies** for all internal applications
2. **Enable device posture** checks for sensitive apps
3. **Rotate service tokens** regularly
4. **Log all access** for audit trails
5. **Use short session durations** for sensitive apps

### Performance

1. **Run cloudflared close** to services (same network)
2. **Use multiple tunnels** for high availability
3. **Enable HTTP/2** for better performance
4. **Monitor tunnel metrics** at localhost:2000

### Reliability

1. **Run as system service** for auto-restart
2. **Use dashboard-managed tunnels** for easier management
3. **Set up monitoring** for tunnel health
4. **Have fallback access** methods
