#!/usr/bin/env bash

#pacman --noconfirm -Sy ansible git

# create a new machine id, required due to cloned AMI
rm /etc/machine-id
systemd-machine-id-setup

UUID=$(cat /etc/machine-id)
ID=$${UUID:0:7}

cat <<EOF >> /etc/environment
UUID=$${UUID}
ID=$${ID}

ANSIBLE="${ansible}"

HOSTNAME=${hostname}-$${ID}

ROLE=${role}
REGION=${region}
IDENTIFIER=${identifier}
ENVIRONMENT=${environment}
EOF

cat <<EOF > /root/.ssh/github
${ansible_key}
EOF

cat <<EOF > /root/.ssh/config
Host github.com
  StrictHostKeyChecking no
  IdentityFile /root/.ssh/github
EOF

cat <<EOF > /etc/systemd/system/bootstrap.service
[Unit]
Description=Ansible Bootstrap
Requires=network-online.target
After=network-online.target

[Service]
Type=oneshot
RemainAfterExit=true

EnvironmentFile=/etc/environment

ExecStartPre=-/usr/bin/git clone \$${ANSIBLE} /root/ansible
ExecStartPre=/usr/bin/git -C /root/ansible fetch
ExecStartPre=/usr/bin/git -C /root/ansible checkout \$${ENVIRONMENT}
ExecStartPre=/usr/bin/git -C /root/ansible pull

ExecStart=/usr/bin/ansible-playbook -i /root/ansible/inventory /root/ansible/archlinux/bootstrap.yml -e "ansible_python_interpreter=/usr/bin/python2"
EOF

chmod 655 /etc/environment

chmod 700 /root/.ssh
chmod 600 /root/.ssh/github
chmod 600 /root/.ssh/config

systemctl restart systemd-journald
systemctl start bootstrap
