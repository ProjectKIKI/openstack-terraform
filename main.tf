terraform {
  required_providers {
    openstack = {
      source  = "terraform-provider-openstack/openstack"
      version = "~> 1.53"
    }
  }
  # OpenTofu 1.5 이상
  required_version = ">= 1.5.0"
}

provider "openstack" {
  # variables.tf에서 받아온 값 사용
  cloud    = var.openstack_cloud
  insecure = var.openstack_insecure
}

########################
# 1. 보안그룹
########################

resource "openstack_networking_secgroup_v2" "allow_icmp_tcp_udp_sg" {
  name        = "allow-icmp-tcp-udp"
  description = "Allow all inbound/outbound ICMP, TCP, UDP"
}

# Ingress ICMP
resource "openstack_networking_secgroup_rule_v2" "icmp_in" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "icmp"
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = openstack_networking_secgroup_v2.allow_icmp_tcp_udp_sg.id
}

# Egress ICMP
resource "openstack_networking_secgroup_rule_v2" "icmp_out" {
  direction         = "egress"
  ethertype         = "IPv4"
  protocol          = "icmp"
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = openstack_networking_secgroup_v2.allow_icmp_tcp_udp_sg.id
}

# Ingress TCP
resource "openstack_networking_secgroup_rule_v2" "tcp_in" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 1
  port_range_max    = 65535
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = openstack_networking_secgroup_v2.allow_icmp_tcp_udp_sg.id
}

# Egress TCP
resource "openstack_networking_secgroup_rule_v2" "tcp_out" {
  direction         = "egress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 1
  port_range_max    = 65535
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = openstack_networking_secgroup_v2.allow_icmp_tcp_udp_sg.id
}

# Ingress UDP
resource "openstack_networking_secgroup_rule_v2" "udp_in" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "udp"
  port_range_min    = 1
  port_range_max    = 65535
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = openstack_networking_secgroup_v2.allow_icmp_tcp_udp_sg.id
}

# Egress UDP
resource "openstack_networking_secgroup_rule_v2" "udp_out" {
  direction         = "egress"
  ethertype         = "IPv4"
  protocol          = "udp"
  port_range_min    = 1
  port_range_max    = 65535
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = openstack_networking_secgroup_v2.allow_icmp_tcp_udp_sg.id
}

########################
# 2. k8s-external 네트워크/서브넷
########################

resource "openstack_networking_network_v2" "k8s_external_net" {
  name           = var.k8s_external_net_name
  admin_state_up = true
}

resource "openstack_networking_subnet_v2" "k8s_external_subnet" {
  name            = var.k8s_external_subnet_name
  network_id      = openstack_networking_network_v2.k8s_external_net.id
  cidr            = var.k8s_external_cidr
  ip_version      = 4
  gateway_ip      = var.k8s_external_gateway_ip
  enable_dhcp     = true
  dns_nameservers = var.k8s_external_dns
}

########################
# 3. k8s-internal 네트워크/서브넷
########################

resource "openstack_networking_network_v2" "k8s_internal_net" {
  name           = var.k8s_internal_net_name
  admin_state_up = true
}

resource "openstack_networking_subnet_v2" "k8s_internal_subnet" {
  name       = var.k8s_internal_subnet_name
  network_id = openstack_networking_network_v2.k8s_internal_net.id
  cidr       = var.k8s_internal_cidr
  ip_version = 4
  # var.k8s_internal_gateway_ip가 빈 문자열("")이면 gateway_ip를 null로 처리
  gateway_ip  = length(var.k8s_internal_gateway_ip) > 0 ? var.k8s_internal_gateway_ip : null
  enable_dhcp = var.k8s_enable_dhcp
}

########################
# 키 페어
########################

resource "openstack_compute_keypair_v2" "auto_gen_key" {
  name = "tofu-key"
  # 공개키를 입력하지 않으면 Terraform이 자동 생성
}

# Private Key 출력 (민감데이터)
output "generated_private_key" {
  description = "This is the newly generated private key from OpenStack"
  value       = openstack_compute_keypair_v2.auto_gen_key.private_key
  sensitive   = true
}

# Public Key 출력
output "generated_public_key" {
  description = "This is the newly generated public key from OpenStack"
  value       = openstack_compute_keypair_v2.auto_gen_key.public_key
}

# Private Key를 로컬 파일로 저장
resource "local_file" "my_private_key_file" {
  content         = openstack_compute_keypair_v2.auto_gen_key.private_key
  filename        = "./tofu-key.pem"
  file_permission = "400"
}

########################
# Infra Port들
########################

data "openstack_networking_network_v2" "infra_net" {
  name = "infra-net" # 실제 네트워크 이름으로 변경
}

resource "openstack_networking_port_v2" "infra_port_controller" {
  name               = "infra-port-controller"
  network_id         = data.openstack_networking_network_v2.infra_net.id
  admin_state_up     = true
  security_group_ids = [openstack_networking_secgroup_v2.allow_icmp_tcp_udp_sg.id]
}

resource "openstack_networking_port_v2" "infra_port_compute1" {
  name               = "infra-port-compute1"
  network_id         = data.openstack_networking_network_v2.infra_net.id
  admin_state_up     = true
  security_group_ids = [openstack_networking_secgroup_v2.allow_icmp_tcp_udp_sg.id]
}

resource "openstack_networking_port_v2" "infra_port_compute2" {
  name               = "infra-port-compute2"
  network_id         = data.openstack_networking_network_v2.infra_net.id
  admin_state_up     = true
  security_group_ids = [openstack_networking_secgroup_v2.allow_icmp_tcp_udp_sg.id]
}

resource "openstack_networking_port_v2" "infra_port_storage" {
  name               = "infra-port-storage"
  network_id         = data.openstack_networking_network_v2.infra_net.id
  admin_state_up     = true
  security_group_ids = [openstack_networking_secgroup_v2.allow_icmp_tcp_udp_sg.id]
}

resource "openstack_networking_port_v2" "infra_port_ansible_server" {
  name               = "infra-port-ansible_server"
  network_id         = data.openstack_networking_network_v2.infra_net.id
  admin_state_up     = true
  security_group_ids = [openstack_networking_secgroup_v2.allow_icmp_tcp_udp_sg.id]
}

########################
# K8s external / internal Port
########################

resource "openstack_networking_port_v2" "k8s_external_port_1" {
  name       = "k8s-external-port-1"
  network_id = openstack_networking_network_v2.k8s_external_net.id
  security_group_ids = [
    openstack_networking_secgroup_v2.allow_icmp_tcp_udp_sg.id
  ]
  fixed_ip {
    subnet_id  = openstack_networking_subnet_v2.k8s_external_subnet.id
    ip_address = var.k8s_external_port_1_ip
  }
}

resource "openstack_networking_port_v2" "k8s_external_port_2" {
  name       = "k8s-external-port-2"
  network_id = openstack_networking_network_v2.k8s_external_net.id
  security_group_ids = [
    openstack_networking_secgroup_v2.allow_icmp_tcp_udp_sg.id
  ]
  fixed_ip {
    subnet_id  = openstack_networking_subnet_v2.k8s_external_subnet.id
    ip_address = var.k8s_external_port_2_ip
  }
}

resource "openstack_networking_port_v2" "k8s_external_port_3" {
  name       = "k8s-external-port-3"
  network_id = openstack_networking_network_v2.k8s_external_net.id
  security_group_ids = [
    openstack_networking_secgroup_v2.allow_icmp_tcp_udp_sg.id
  ]
  fixed_ip {
    subnet_id  = openstack_networking_subnet_v2.k8s_external_subnet.id
    ip_address = var.k8s_external_port_3_ip
  }
}

resource "openstack_networking_port_v2" "k8s_internal_port_1" {
  name       = "k8s_internal_port_1"
  network_id = openstack_networking_network_v2.k8s_internal_net.id
  security_group_ids = [
    openstack_networking_secgroup_v2.allow_icmp_tcp_udp_sg.id
  ]
  fixed_ip {
    subnet_id  = openstack_networking_subnet_v2.k8s_internal_subnet.id
    ip_address = var.k8s_internal_port_1_ip
  }
}

resource "openstack_networking_port_v2" "k8s_internal_port_2" {
  name       = "k8s_internal_port_2"
  network_id = openstack_networking_network_v2.k8s_internal_net.id
  security_group_ids = [
    openstack_networking_secgroup_v2.allow_icmp_tcp_udp_sg.id
  ]
  fixed_ip {
    subnet_id  = openstack_networking_subnet_v2.k8s_internal_subnet.id
    ip_address = var.k8s_internal_port_2_ip
  }
}

resource "openstack_networking_port_v2" "k8s_internal_port_3" {
  name       = "k8s_internal_port_3"
  network_id = openstack_networking_network_v2.k8s_internal_net.id
  security_group_ids = [
    openstack_networking_secgroup_v2.allow_icmp_tcp_udp_sg.id
  ]
  fixed_ip {
    subnet_id  = openstack_networking_subnet_v2.k8s_internal_subnet.id
    ip_address = var.k8s_internal_port_3_ip
  }
}

resource "openstack_networking_port_v2" "k8s_internal_port_4" {
  name       = "k8s_internal_port_4"
  network_id = openstack_networking_network_v2.k8s_internal_net.id
  security_group_ids = [
    openstack_networking_secgroup_v2.allow_icmp_tcp_udp_sg.id
  ]
  fixed_ip {
    subnet_id  = openstack_networking_subnet_v2.k8s_internal_subnet.id
    ip_address = var.k8s_internal_port_4_ip
  }
}

resource "openstack_networking_port_v2" "k8s_internal_port_5" {
  name       = "k8s_internal_port_5"
  network_id = openstack_networking_network_v2.k8s_internal_net.id
  security_group_ids = [
    openstack_networking_secgroup_v2.allow_icmp_tcp_udp_sg.id
  ]
  fixed_ip {
    subnet_id  = openstack_networking_subnet_v2.k8s_internal_subnet.id
    ip_address = var.k8s_internal_port_5_ip
  }
}

########################
# 1) Ansible Server
########################
resource "openstack_compute_instance_v2" "ansible_server" {
  name        = var.ansible_server_name
  flavor_name = var.openstack_flavor_name
  image_id    = var.openstack_image_id
  key_pair    = openstack_compute_keypair_v2.auto_gen_key.name

  network {
    port = openstack_networking_port_v2.infra_port_ansible_server.id
  }

  network {
    port = openstack_networking_port_v2.k8s_internal_port_1.id
  }

  network {
    port = openstack_networking_port_v2.k8s_external_port_1.id
  }

  user_data = templatefile(
    "${path.module}/${var.cloud_init_template}",
    { public_key = openstack_compute_keypair_v2.auto_gen_key.public_key }
  )

  config_drive = true
}

########################
# 2) Controller Node
########################
resource "openstack_compute_instance_v2" "controller_node" {
  name        = var.controller_node_name
  flavor_name = var.openstack_flavor_name
  image_id    = var.openstack_image_id
  key_pair    = openstack_compute_keypair_v2.auto_gen_key.name

  network {
    port = openstack_networking_port_v2.infra_port_controller.id
  }

  network {
    port = openstack_networking_port_v2.k8s_internal_port_2.id
  }

  user_data = templatefile(var.cloud_init_template, {
    public_key = openstack_compute_keypair_v2.auto_gen_key.public_key
  })

  config_drive = true
}

########################
# 3) Compute Node1
########################
resource "openstack_compute_instance_v2" "compute_node1" {
  name        = var.compute_node1_name
  flavor_name = var.openstack_flavor_name
  image_id    = var.openstack_image_id
  key_pair    = openstack_compute_keypair_v2.auto_gen_key.name

  network {
    port = openstack_networking_port_v2.infra_port_compute1.id
  }

  network {
    port = openstack_networking_port_v2.k8s_internal_port_3.id
  }

  network {
    port = openstack_networking_port_v2.k8s_external_port_2.id
  }

  user_data = templatefile(var.cloud_init_template, {
    public_key = openstack_compute_keypair_v2.auto_gen_key.public_key
  })

  config_drive = true
}

########################
# 4) Compute Node2
########################
resource "openstack_compute_instance_v2" "compute_node2" {
  name        = var.compute_node2_name
  flavor_name = var.openstack_flavor_name
  image_id    = var.openstack_image_id
  key_pair    = openstack_compute_keypair_v2.auto_gen_key.name

  network {
    port = openstack_networking_port_v2.infra_port_compute2.id
  }

  network {
    port = openstack_networking_port_v2.k8s_internal_port_4.id
  }

  network {
    port = openstack_networking_port_v2.k8s_external_port_3.id
  }

  user_data = templatefile(var.cloud_init_template, {
    public_key = openstack_compute_keypair_v2.auto_gen_key.public_key
  })

  config_drive = true
}

########################
# 5) Storage Node
########################
resource "openstack_compute_instance_v2" "storage_node" {
  name        = var.storage_node_name
  flavor_name = var.openstack_flavor_name
  image_id    = var.openstack_image_id
  key_pair    = openstack_compute_keypair_v2.auto_gen_key.name

  network {
    port = openstack_networking_port_v2.infra_port_storage.id
  }

  network {
    port = openstack_networking_port_v2.k8s_internal_port_5.id
  }

  user_data = templatefile(var.cloud_init_template, {
    public_key = openstack_compute_keypair_v2.auto_gen_key.public_key
  })

  config_drive = true
}
