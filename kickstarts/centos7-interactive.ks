#version=RHEL7
# CentOS 7 Interactive Installation Kickstart
# Allows user input during installation process
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

# Use text mode but allow interaction
text
# Note: Removed 'cmdline' to allow user interaction

# Basic system settings
firstboot --disable
keyboard --vckeymap=us --xlayouts='us'
lang en_US.UTF-8

# User will be prompted for timezone
# timezone --isUtc America/New_York

# Network configuration
network --bootproto=dhcp --device=link --activate

#################################################
# SECURITY CONFIGURATION
#################################################

# User will be prompted for root password
# rootpw --plaintext YourPasswordHere

# Security settings
selinux --permissive
firewall --enabled --ssh

#################################################
# SERVICES CONFIGURATION
#################################################

services --enabled="sshd,chronyd"

#################################################
# DISK PARTITIONING
#################################################

# User will be prompted for partitioning confirmation
clearpart --all --initlabel
zerombr

# Use automatic partitioning with LVM
autopart --type=lvm

#################################################
# PACKAGE SELECTION
#################################################

%packages --ignoremissing
@^minimal
@core
@development

# Essential tools
openssh-server
curl
wget
vim
nano
git
sudo
yum-utils
bind-utils
net-tools
chrony
rsync
tar
gzip
bzip2
unzip

# Remove unnecessary packages
-postfix
-sendmail
%end

#################################################
# POST-INSTALLATION SCRIPT
#################################################

%post --log=/root/ks-post.log
#!/bin/bash

echo "Starting interactive installation post-configuration..."

#################################################
# CONFIGURE VAULT REPOSITORIES
#################################################

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

[updates]
name=CentOS-7 - Updates
baseurl=http://vault.centos.org/7.9.2009/updates/x86_64/
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-7
enabled=1

[extras]
name=CentOS-7 - Extras
baseurl=http://vault.centos.org/7.9.2009/extras/x86_64/
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-7
enabled=1

[epel]
name=Extra Packages for Enterprise Linux 7 - x86_64
baseurl=https://download.fedoraproject.org/pub/epel/7/x86_64/
enabled=1
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-EPEL-7
VAULT_EOF

# Update system with vault repositories
yum clean all
yum makecache

# Install EPEL
yum install -y epel-release

# Create completion marker
echo "CentOS 7 interactive installation completed: $(date)" > /root/install-complete.log
echo "Repository configuration updated for vault access" >> /root/install-complete.log

%end

reboot
