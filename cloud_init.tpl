#cloud-config
write_files:
  - path: /root/.ssh/authorized_keys
    permissions: "0600"
    content: |
      ${public_key}

runcmd:
  - echo "${public_key}" > /root/.ssh/authorized_keys
  - sed -i 's/^#*PermitRootLogin .*/PermitRootLogin yes/' /etc/ssh/sshd_config
  - rm -f /etc/ssh/sshd_config.d/50-cloud-init.conf
  # SSH 데몬 재시작
  - systemctl restart sshd
