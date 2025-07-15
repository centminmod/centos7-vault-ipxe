# Troubleshooting Guide

## Common Installation Issues

### 1. iPXE Script Not Loading

**Symptoms:**
- VPS shows iPXE shell instead of custom script
- "Could not boot" errors

**Solutions:**
```bash
# Test GitHub Pages URL manually
curl -I https://username.github.io/repo/ipxe/centos7-vault.ipxe

# Verify GitHub Pages is enabled
# Check repository settings → Pages

# Test basic connectivity
ping github.io
```

### 2. Kernel Download Failures

**Symptoms:**
- "Download failed" errors
- Timeout during kernel/initrd download

**Solutions:**
```bash
# Test vault connectivity
ping vault.centos.org
curl -I http://vault.centos.org/7.9.2009/os/x86_64/images/pxeboot/vmlinuz

# Check VPS outbound connectivity
# Verify no firewall blocking HTTP traffic
```

### 3. Installation Hangs

**Symptoms:**
- Installation starts but stops responding
- Anaconda installer freezes

**Solutions:**
- Ensure VPS has sufficient resources (≥1GB RAM, ≥25GB disk)
- Check console for error messages
- Try different VPS plan or region
- Use interactive kickstart for debugging

### 4. SSH Access Issues

**Symptoms:**
- Cannot SSH after installation
- Connection refused errors

**Solutions:**
```bash
# Check SSH service status via console
systemctl status sshd

# Verify SSH configuration
cat /etc/ssh/sshd_config | grep -E "(PermitRootLogin|PubkeyAuth|PasswordAuth)"

# Check firewall settings
firewall-cmd --list-services
```

## Advanced Debugging

### iPXE Debug Commands

When dropped to iPXE shell:
```bash
# Show network configuration
ifstat

# Show routing table
route

# Test connectivity
ping 8.8.8.8

# Reconfigure network
dhcp

# Manual kernel loading
kernel http://vault.centos.org/7.9.2009/os/x86_64/images/pxeboot/vmlinuz
initrd http://vault.centos.org/7.9.2009/os/x86_64/images/pxeboot/initrd.img
boot
```

### Kickstart Debugging

Enable kickstart debugging:
```bash
# Add to kernel command line
inst.ks=https://your-url/kickstart.ks inst.debug
```

Check logs during installation:
```bash
# Switch to shell (Ctrl+Alt+F2)
tail -f /tmp/anaconda.log
tail -f /tmp/program.log
tail -f /tmp/storage.log
```
