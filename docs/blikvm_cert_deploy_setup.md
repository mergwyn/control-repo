# BliKVM Certificate Deploy — One-Time Setup

## Overview

Certificates issued by `profile::app::acme` on Delta are automatically deployed
to BliKVM on renewal and at Delta boot. This document covers the one-time manual
steps required to enable this.

## Prerequisites

- `profile::app::acme` applied to Delta
- `profile::app::blikvm` applied to Delta
- SSH access to BliKVM (password or console)

---

## Step 1 — Generate Deploy Key on Delta

```bash
mkdir -p /etc/acme/.ssh
chmod 700 /etc/acme/.ssh
ssh-keygen -t ed25519 -f /etc/acme/.ssh/blikvm_deploy -N "" -C "acme-deploy@delta"
```

Copy the public key to clipboard:

```bash
cat /etc/acme/.ssh/blikvm_deploy.pub
```

---

## Step 2 — Install Public Key on BliKVM

SSH or use the BliKVM console. The filesystem is read-only by default — remount first:

```bash
mount -o remount,rw /
mkdir -p /root/.ssh
chmod 700 /root/.ssh
echo "<paste public key here>" >> /root/.ssh/authorized_keys
chmod 600 /root/.ssh/authorized_keys
mount -o remount,ro /
```

---

## Step 3 — Test SSH Access from Delta

```bash
ssh -i /etc/acme/.ssh/blikvm_deploy -o StrictHostKeyChecking=accept-new root@blikvm-lan "echo ok"
```

The `StrictHostKeyChecking=accept-new` flag accepts and saves the host key on first
connection. Subsequent connections will verify it automatically.

---

## Step 4 — Verify Deploy Script

Trigger a manual run to confirm end-to-end:

```bash
/etc/acme/deploy.d/10-blikvm.sh
```

Check BliKVM nginx config and services:

```bash
ssh -i /etc/acme/.ssh/blikvm_deploy root@blikvm-lan "nginx -t && systemctl is-active kvmd-web kvmd-nginx"
```

---

## What Puppet Manages

| Resource | Location |
|---|---|
| Deploy script | `/etc/acme/deploy.d/10-blikvm.sh` |
| SSH deploy key (private) | `/etc/acme/.ssh/blikvm_deploy` *(created manually)* |
| Boot deploy service | `acme-deploy-blikvm.service` |
| Boot deploy timer | `acme-deploy-blikvm.timer` |

## What Requires Manual Setup

| Task | When |
|---|---|
| Generate SSH key pair on Delta | Once, after first Puppet run |
| Install public key on BliKVM | Once |
| Accept BliKVM SSH host key | Once, on first deploy script run |

---

## Renewal Flow

1. `acme.sh` renews cert via DNS-01 (Cloudflare)
2. `--reloadcmd` runs all scripts in `/etc/acme/deploy.d/`
3. `10-blikvm.sh` deploys cert to BliKVM and restarts kvmd services

## Boot Flow

1. `acme-deploy-blikvm.timer` fires 5 minutes after Delta boots
2. `acme-deploy-blikvm.service` runs `10-blikvm.sh`
3. Ensures BliKVM has current certs even if Delta was down during last renewal
