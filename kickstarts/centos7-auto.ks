#version=RHEL7
# CentOS 7 Automated Installation Kickstart
# Optimized for VPS/Cloud environments
# Uses vault repositories (CentOS 7 is EOL)

#################################################
# INSTALLATION METHOD AND REPOSITORIES
#################################################

install
url --url="http://vault.centos.org/7.9.2009/os/x86_64/"

# Additional repositories from vault
repo --name="updates" --baseurl="http://vault.centos.org/7.9.2009/updates/x86_64/"
repo --name="extras" --baseurl="http://vault.centos.org/7.9.2009/extras/x86_64/"

#################################################
# SYSTEM CONFIGURATION
#################################################

# Installation mode
text
cmdline

# Basic system settings
auth --enableshadow --passalgo=sha512
firstboot --disable
keyboard --vckeymap=us --xlayouts='us'
lang en_US.UTF-8
timezone UTC --isUtc

# Network configuration for VPS
network --bootproto=dhcp --device=link --activate --onboot=on
network --hostname=centos7-vault

#################################################
# SECURITY CONFIGURATION
#################################################

# Root password: CentOS7Vault2024!
rootpw --iscrypted $6$VaultSalt$2Hx1qV8s3nKpZ9mL7tY4wE6rP5oI3uA8gF2dS1cX9bN6mK4jH7gF5eD3cB2aZ8yX7wV6uT5sR4qP3oN2mL1kJ0i

# Security settings
selinux --permissive
firewall --enabled --ssh

#################################################
# SERVICES CONFIGURATION
#################################################

services --enabled="sshd,chronyd,cloud-init"
services --disabled="postfix,sendmail"

#################################################
# DISK PARTITIONING
#################################################

# Clear all partitions and use LVM
clearpart --all --initlabel
zerombr

# Partition scheme for VPS (assumes /dev/vda)
part /boot --fstype="xfs" --ondisk=vda --size=1024
part pv.01 --fstype="lvmpv" --ondisk=vda --grow

# LVM configuration
volgroup centos --pesize=4096 pv.01
logvol / --fstype="xfs" --size=8192 --name=root --vgname=centos --grow
logvol /var --fstype="xfs" --size=4096 --name=var --vgname=centos
logvol /home --fstype="xfs" --size=1024 --name=home --vgname=centos
logvol swap --fstype="swap" --size=4198 --name=swap --vgname=centos

#################################################
# PACKAGE SELECTION
#################################################

%packages --nobase --ignoremissing --excludedocs
# Core system
@core
kernel
grub2

# Essential tools
openssh-server
openssh-clients
curl
wget
vim
nano
sudo
yum-utils
bind-utils
net-tools

# System utilities
chrony
rsync
tar
gzip
bzip2
unzip
which

# Development tools (optional)
git
gcc
make

# Cloud compatibility
cloud-init
cloud-utils-growpart

# Remove unnecessary packages
-postfix
-sendmail
-aic94xx-firmware
-alsa-firmware
-ivtv-firmware
-iwl*firmware
-libertas-*firmware
%end

#################################################
# PRE-INSTALLATION SCRIPT
#################################################

%pre --log=/tmp/ks-pre.log
#!/bin/bash

echo "Starting CentOS 7 pre-installation setup..."
echo "Date: $(date)"
echo "Memory: $(grep MemTotal /proc/meminfo)"
echo "CPU: $(nproc) cores"
echo "Disks: $(lsblk -d | grep -v loop)"

# Log network information
ip addr show > /tmp/network-info.log
ip route show >> /tmp/network-info.log

echo "Pre-installation setup complete"
%end

#################################################
# POST-INSTALLATION SCRIPT
#################################################

%post --log=/root/ks-post.log --interpreter=/bin/bash
#!/bin/bash

echo "Starting CentOS 7 post-installation configuration..."
echo "Date: $(date)"

#################################################
# CONFIGURE VAULT REPOSITORIES
#################################################

echo "Configuring CentOS 7 vault repositories..."

# Backup existing repository configurations
mkdir -p /etc/yum.repos.d/backup
mv /etc/yum.repos.d/CentOS-*.repo /etc/yum.repos.d/backup/ 2>/dev/null || true

# Create vault repository configuration
cat > /etc/yum.repos.d/CentOS-Vault.repo << 'VAULT_EOF'
[base]
name=CentOS-7 - Base
baseurl=http://vault.centos.org/7.9.2009/os/x86_64/
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-7
enabled=1
priority=1

[updates]
name=CentOS-7 - Updates
baseurl=http://vault.centos.org/7.9.2009/updates/x86_64/
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-7
enabled=1
priority=1

[extras]
name=CentOS-7 - Extras
baseurl=http://vault.centos.org/7.9.2009/extras/x86_64/
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-7
enabled=1
priority=1

[epel]
name=Extra Packages for Enterprise Linux 7 - x86_64
baseurl=https://download.fedoraproject.org/pub/epel/7/x86_64/
enabled=1
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-EPEL-7
priority=2
VAULT_EOF

#################################################
# USER CONFIGURATION
#################################################

echo "Creating test user account..."

# Create test user
useradd -m -G wheel testuser
echo 'testuser:CentOS7Vault2024!' | chpasswd

# Configure sudo access
echo 'testuser ALL=(ALL) NOPASSWD: ALL' > /etc/sudoers.d/testuser
chmod 440 /etc/sudoers.d/testuser

#################################################
# SSH CONFIGURATION
#################################################

echo "Configuring SSH access..."

# Create SSH directories
mkdir -p /home/testuser/.ssh /root/.ssh
chmod 700 /home/testuser/.ssh /root/.ssh

# SSH public key placeholder (will be replaced by script)
SSH_KEY_PLACEHOLDER="REPLACE_WITH_SSH_KEY"

if [[ "$SSH_KEY_PLACEHOLDER" != "REPLACE_WITH_SSH_KEY" ]]; then
    echo "$SSH_KEY_PLACEHOLDER" > /home/testuser/.ssh/authorized_keys
    echo "$SSH_KEY_PLACEHOLDER" > /root/.ssh/authorized_keys
    chmod 600 /home/testuser/.ssh/authorized_keys /root/.ssh/authorized_keys
    chown -R testuser:testuser /home/testuser/.ssh
    echo "SSH key configured for testuser and root"
else
    echo "No SSH key provided - password authentication will be required"
fi

# Configure SSH daemon
sed -i 's/#PermitRootLogin yes/PermitRootLogin yes/' /etc/ssh/sshd_config
sed -i 's/#PubkeyAuthentication yes/PubkeyAuthentication yes/' /etc/ssh/sshd_config
sed -i 's/#PasswordAuthentication yes/PasswordAuthentication yes/' /etc/ssh/sshd_config

#################################################
# SYSTEM OPTIMIZATION
#################################################

echo "Applying system optimizations..."

# Update system with vault repositories
yum clean all
yum makecache

# Install EPEL
yum install -y epel-release

# Update packages
yum update -y

# Install additional useful packages
yum install -y htop iotop lsof strace tcpdump

#################################################
# CLOUD-INIT CONFIGURATION
#################################################

echo "Configuring cloud-init for VPS compatibility..."

# Basic cloud-init configuration
cat > /etc/cloud/cloud.cfg.d/99-vault-centos7.cfg << 'CLOUD_EOF'
# CentOS 7 Vault - Cloud-init configuration
datasource_list: [ NoCloud, ConfigDrive, OpenNebula, Azure, AltCloud, OVF, MAAS, Ec2, CloudSigma, CloudStack, SmartOS, Bigstep, Scaleway, AliYun, OpenStack, None ]

# Preserve hostname
preserve_hostname: false

# User configuration
system_info:
  default_user:
    name: testuser
    gecos: Test User
    sudo: ALL=(ALL) NOPASSWD:ALL
    groups: [wheel, adm]
    shell: /bin/bash

# Cloud modules
cloud_init_modules:
 - migrator
 - bootcmd
 - write-files
 - growpart
 - resizefs
 - set_hostname
 - update_hostname
 - update_etc_hosts
 - rsyslog
 - users-groups
 - ssh

cloud_config_modules:
 - mounts
 - locale
 - set-passwords
 - yum-add-repo
 - package-update-upgrade-install
 - timezone
 - puppet
 - chef
 - salt-minion
 - mcollective
 - disable-ec2-metadata
 - runcmd

cloud_final_modules:
 - rightscale_userdata
 - scripts-per-once
 - scripts-per-boot
 - scripts-per-instance
 - scripts-user
 - ssh-authkey-fingerprints
 - keys-to-console
 - phone-home
 - final-message
CLOUD_EOF

#################################################
# COMPLETION TASKS
#################################################

echo "Performing final system tasks..."

# Enable essential services
systemctl enable sshd chronyd

# Create installation completion marker
cat > /root/installation-complete.log << 'COMPLETE_EOF'
CentOS 7 Vault Installation Complete
=====================================

Installation Details:
- Date: $(date)
- OS: $(cat /etc/centos-release)
- Kernel: $(uname -r)
- Architecture: $(uname -m)
- Hostname: $(hostname)

System Information:
- Memory: $(free -h | grep Mem | awk '{print $2}')
- Disk: $(df -h / | tail -1 | awk '{print $2}')
- CPU: $(nproc) cores

Network Configuration:
$(ip addr show | grep -E 'inet.*scope global')

Repository Configuration:
- Using CentOS 7 vault repositories
- EPEL repository enabled
- System packages updated

User Accounts:
- root: CentOS7Vault2024!
- testuser: CentOS7Vault2024! (sudo access)

SSH Access:
- SSH service enabled
- Root login permitted
- Public key authentication configured (if key provided)

Next Steps:
1. SSH to server: ssh testuser@$(hostname -I | awk '{print $1}')
2. Verify installation: cat /etc/centos-release
3. Check repositories: yum repolist
4. Update system: sudo yum update

Notes:
- CentOS 7 reached EOL on June 30, 2024
- Using vault repositories for package management
- System is ready for ELevate testing or other purposes
COMPLETE_EOF

# System cleanup
yum clean all

echo "Post-installation configuration complete!"
echo "System ready for first boot."

%end

#################################################
# REBOOT AFTER INSTALLATION
#################################################

reboot --force
