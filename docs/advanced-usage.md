# Advanced Usage Guide

## Custom Kickstart Configuration

### Adding Custom Packages

Edit `%packages` section in kickstart:
```bash
%packages --ignoremissing
@core
@development
# Add your packages here
htop
iotop
strace
tcpdump
%end
```

### Custom Partitioning

Replace autopart with custom scheme:
```bash
# Clear existing partitions
clearpart --all --initlabel
zerombr

# Custom partition layout
part /boot --fstype="xfs" --ondisk=vda --size=1024
part /boot/efi --fstype="efi" --ondisk=vda --size=512
part pv.01 --fstype="lvmpv" --ondisk=vda --grow

# LVM configuration
volgroup system --pesize=4096 pv.01
logvol / --fstype="xfs" --size=10240 --name=root --vgname=system
logvol /var --fstype="xfs" --size=5120 --name=var --vgname=system
logvol /var/log --fstype="xfs" --size=2048 --name=log --vgname=system
logvol /tmp --fstype="xfs" --size=2048 --name=tmp --vgname=system
logvol /home --fstype="xfs" --size=1024 --name=home --vgname=system --grow
logvol swap --fstype="swap" --size=2048 --name=swap --vgname=system
```

### Network Configuration

Static IP configuration:
```bash
network --bootproto=static --device=eth0 --gateway=192.168.1.1 --ip=192.168.1.100 --nameserver=8.8.8.8 --netmask=255.255.255.0 --activate
```

## iPXE Script Customization

### Environment Variables

Add custom variables:
```bash
set custom_var value
echo Custom variable: ${custom_var}
```

### Multiple Boot Options

Create menu system:
```bash
:menu
menu CentOS 7 Installation Options
item auto Automated Installation
item interactive Interactive Installation
item shell iPXE Shell
choose option && goto ${option}

:auto
set ks_opts inst.ks=https://example.com/auto.ks
goto boot

:interactive
set ks_opts
goto boot

:shell
shell

:boot
kernel ${centos_kernel} ${base_opts} ${ks_opts}
initrd ${centos_initrd}
boot
```

### Custom Console Options

For different console types:
```bash
# Serial console only
set console_opts console=ttyS0,115200n8

# VGA console only
set console_opts console=tty0

# Both consoles
set console_opts console=ttyS0,115200n8 console=tty0
```

## Multiple Provider Support

### DigitalOcean Custom Images

1. Create CentOS 7 snapshot
2. Upload as custom image
3. Deploy droplets from custom image

### Hetzner Rescue System

1. Boot into rescue system
2. Download CentOS 7 ISO
3. Manual installation using VNC

### Linode Custom Deployment

1. Use Linode's custom image feature
2. Boot from custom iPXE URL
3. Follow standard installation

## Automation Scripts

### Batch VPS Creation

```bash
#!/bin/bash
# Create multiple CentOS 7 test instances

for i in {1..5}; do
    name="centos7-test-$(printf "%02d" $i)"
    curl -X POST "https://api.vultr.com/v2/instances" \
        -H "Authorization: Bearer $VULTR_API_KEY" \
        -H "Content-Type: application/json" \
        -d "{
            \"region\": \"ewr\",
            \"plan\": \"vhp-2c-4gb-amd\",
            \"os_id\": \"159\",
            \"label\": \"$name\",
            \"ipxe_chain_url\": \"$IPXE_URL\"
        }"
    echo "Created: $name"
    sleep 5
done
```

### Installation Monitoring

```bash
#!/bin/bash
# Monitor installation progress

INSTANCE_IDS=("id1" "id2" "id3")

while true; do
    for id in "${INSTANCE_IDS[@]}"; do
        status=$(curl -s -H "Authorization: Bearer $VULTR_API_KEY" \
            "https://api.vultr.com/v2/instances/$id" | \
            jq -r '.instance.status')
        echo "Instance $id: $status"
    done
    sleep 30
done
```

## Testing and Validation

### Post-Installation Tests

```bash
#!/bin/bash
# Validate CentOS 7 installation

echo "=== System Information ==="
cat /etc/centos-release
uname -a

echo "=== Repository Configuration ==="
yum repolist

echo "=== Network Configuration ==="
ip addr show
ip route show

echo "=== Disk Usage ==="
df -h

echo "=== Memory Usage ==="
free -h

echo "=== Services ==="
systemctl is-active sshd chronyd

echo "=== Connectivity Tests ==="
ping -c 3 8.8.8.8
curl -s http://vault.centos.org/ > /dev/null && echo "Vault accessible" || echo "Vault not accessible"
```

### ELevate Preparation Test

```bash
#!/bin/bash
# Test ELevate prerequisites

echo "=== ELevate Preparation Test ==="

# Check disk space
root_space=$(df / | tail -1 | awk '{print $4}')
if [[ $root_space -gt 5000000 ]]; then
    echo "✓ Sufficient disk space"
else
    echo "✗ Insufficient disk space"
fi

# Check memory
mem_gb=$(free -g | grep Mem | awk '{print $2}')
if [[ $mem_gb -ge 2 ]]; then
    echo "✓ Sufficient memory"
else
    echo "⚠ Low memory"
fi

# Install ELevate
echo "Installing ELevate..."
yum install -y http://repo.almalinux.org/elevate/elevate-release-latest-el7.noarch.rpm
yum install -y leapp-upgrade leapp-data-almalinux

# Run pre-upgrade check
echo "Running pre-upgrade check..."
leapp preupgrade --target 8.6

echo "=== Test Complete ==="
```
