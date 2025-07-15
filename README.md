# CentOS 7 Vault iPXE Installation

Custom iPXE scripts for installing CentOS 7 from vault repositories when netboot.xyz no longer provides CentOS 7 support.

## 🎯 Purpose

- **Problem**: netboot.xyz removed CentOS 7 after EOL (June 2024)
- **Solution**: Direct iPXE scripts pointing to vault.centos.org
- **Use Case**: ELevate testing, legacy system evaluation, migration testing

## 📁 Repository Structure

```
centos7-vault-ipxe/
├── ipxe/
│   └── centos7-vault.ipxe      # Main iPXE boot script
├── kickstarts/
│   ├── centos7-auto.ks         # Automated installation
│   └── centos7-interactive.ks  # Interactive installation
├── docs/
│   ├── troubleshooting.md      # Common issues and solutions
│   └── advanced-usage.md       # Advanced configuration options
└── README.md                   # This file
```

## 🚀 Quick Start

### 1. Vultr iPXE Installation

```bash
# Set your variables
VULTR_API_KEY="your-vultr-api-key-here"
curl -s "https://api.vultr.com/v2/ssh-keys"   -X GET   -H "Authorization: Bearer " | jq -r
```

```bash
curl -X POST "https://api.vultr.com/v2/instances" \\
  -H "Authorization: Bearer $VULTR_API_KEY" \\
  -H "Content-Type: application/json" \\
  -d '{
    "region": "ewr",
    "plan": "vhp-2c-4gb-amd",
    "os_id": "159",
    "sshkey_id": "'$SSHKEY_ID'",
    "label": "centos7-vault-test",
    "ipxe_chain_url": "https://centminmod.github.io/centos7-vault-ipxe/ipxe/centos7-vault.ipxe"
  }'
```

### 2. Access Installation

- **Console**: Vultr console → Watch installation progress
- **SSH**: Available after installation completes

### 3. Login Credentials

**Automated Installation:**
- Root: `CentOS7Vault2024!`
- User: `testuser` / `CentOS7Vault2024!`

**Interactive Installation:**
- Credentials set during installation

## 📋 Installation Options

### Option A: Interactive Installation (Default)

- Uses iPXE script as-is
- Prompts for configuration during install
- Full control over setup process
- Recommended for learning/testing

### Option B: Automated Installation

1. Edit `ipxe/centos7-vault.ipxe`
2. Uncomment kickstart lines:
   ```bash
   # set kickstart_url https://centminmod.github.io/centos7-vault-ipxe/kickstarts/centos7-auto.ks
   # set ks_opts inst.ks=${kickstart_url}
   ```
3. Commit and push changes
4. Create VPS with updated iPXE URL

## 🔧 Post-Installation

### Verify Installation

```bash
# Check OS version
cat /etc/centos-release

# Verify vault repositories
yum repolist

# Check system status
systemctl status sshd
df -h
free -m
```

### Update System

```bash
# Update all packages
sudo yum clean all
sudo yum update -y

# Install additional packages
sudo yum install -y htop iotop lsof
```

## 🌐 URLs

- **iPXE Script**: https://centminmod.github.io/centos7-vault-ipxe/ipxe/centos7-vault.ipxe
- **Auto Kickstart**: https://centminmod.github.io/centos7-vault-ipxe/kickstarts/centos7-auto.ks
- **Interactive KS**: https://centminmod.github.io/centos7-vault-ipxe/kickstarts/centos7-interactive.ks

## ⚠️ Important Notes

### CentOS 7 End of Life

- **EOL Date**: June 30, 2024
- **No Security Updates**: System vulnerable to new threats
- **Testing Only**: Not suitable for production use
- **Migration Path**: Use for ELevate testing to modern OS

### Repository Configuration

All scripts automatically configure vault repositories:

```ini
[base]
baseurl=http://vault.centos.org/7.9.2009/os/x86_64/

[updates] 
baseurl=http://vault.centos.org/7.9.2009/updates/x86_64/

[extras]
baseurl=http://vault.centos.org/7.9.2009/extras/x86_64/
```

## 🛠️ Troubleshooting

### Installation Fails to Start

1. **Check iPXE URL**: Verify GitHub Pages is active
2. **Test Network**: Ensure DHCP works in VPS
3. **Verify Console**: Use Vultr console for error messages

### Boot Loop or Kernel Panic

1. **Memory**: Ensure VPS has ≥1GB RAM
2. **Disk Space**: Verify ≥25GB available
3. **Hardware**: Some VPS types may have compatibility issues

### Network Issues

1. **DNS**: Script uses 8.8.8.8 for DNS
2. **Connectivity**: Test `ping vault.centos.org`
3. **Firewall**: Check VPS provider firewall rules

### Package Installation Fails

1. **Repository**: Verify vault.centos.org accessibility
2. **GPG Keys**: May need manual key import
3. **Network**: Check outbound HTTP/HTTPS access

## 📚 Additional Resources

- [CentOS Vault Archive](http://vault.centos.org/)
- [iPXE Documentation](https://ipxe.org/)
- [Kickstart Reference](https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/7/html/installation_guide/sect-kickstart-syntax)
- [ELevate Project](https://github.com/AlmaLinux/leapp-repository)

## 🤝 Contributing

1. Fork this repository
2. Create your feature branch
3. Test thoroughly on VPS
4. Submit pull request with detailed description

## 📄 License

This project is provided as-is for educational and testing purposes. CentOS 7 is EOL and should not be used in production.

---

**Created**: Mon Jul 14 10:02:25 PM PDT 2025  
**Repository**: https://github.com/centminmod/centos7-vault-ipxe  
**Issues**: https://github.com/centminmod/centos7-vault-ipxe/issues
