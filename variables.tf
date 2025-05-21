variable "openstack_cloud" {
  type        = string
  description = "clouds.yaml의 cloud 이름"
  default     = "openstack"
}

variable "openstack_insecure" {
  type        = bool
  description = "내부 TLS 인증서를 무시할지 여부(insecure). true면 인증 무시"
  default     = true
}

variable "openstack_image_id" {
  type        = string
  description = "인스턴스 생성 시 사용할 OpenStack 이미지 ID (Rocky9)"
  default     = "c7bbf35b-753f-4e3b-940a-f6b4367f4511"
}

variable "openstack_flavor_name" {
  type        = string
  description = "인스턴스 생성 시 사용할 OpenStack Flavor 이름"
  default     = "r1.kubernetes"
}

variable "k8s_external_net_name" {
  type        = string
  description = "K8s External 네트워크 이름"
  default     = "k8s-external"
}

variable "k8s_external_subnet_name" {
  type        = string
  description = "K8s External 서브넷 이름"
  default     = "k8s-external-subnet"
}

variable "k8s_external_cidr" {
  type        = string
  description = "K8s External 서브넷 CIDR"
  default     = "10.10.10.0/24"
}

variable "k8s_external_gateway_ip" {
  type        = string
  description = "K8s External 서브넷 게이트웨이 IP"
  default     = "10.10.10.254"
}

variable "k8s_external_dns" {
  type        = list(string)
  description = "K8s External 서브넷의 DNS 서버 목록"
  default     = ["8.8.8.8"]
}

variable "k8s_internal_net_name" {
  type        = string
  description = "K8s Internal 네트워크 이름"
  default     = "k8s-internal"
}

variable "k8s_internal_subnet_name" {
  type        = string
  description = "K8s Internal 서브넷 이름"
  default     = "k8s-internal-subnet"
}

variable "k8s_internal_cidr" {
  type        = string
  description = "K8s Internal 서브넷 CIDR"
  default     = "192.168.0.0/16"
}

variable "k8s_internal_gateway_ip" {
  type        = string
  description = "K8s Internal 서브넷 게이트웨이 IP (null이면 게이트웨이 없음)"
  default     = ""
}

variable "k8s_enable_dhcp" {
  type        = bool
  description = "K8s Internal 서브넷에서 DHCP를 활성화할지 여부"
  default     = true
}

# 포트에 할당할 IP를 개별 변수로 분리(예: 외부, 내부 등)
variable "k8s_external_port_1_ip" {
  type        = string
  description = "k8s-external-port-1 IP"
  default     = "10.10.10.10"
}

variable "k8s_external_port_2_ip" {
  type        = string
  description = "k8s-external-port-2 IP"
  default     = "10.10.10.20"
}

variable "k8s_external_port_3_ip" {
  type        = string
  description = "k8s-external-port-3 IP"
  default     = "10.10.10.30"
}

variable "k8s_internal_port_1_ip" {
  type        = string
  description = "k8s_internal_port_1 IP"
  default     = "192.168.10.100"
}

variable "k8s_internal_port_2_ip" {
  type        = string
  description = "k8s_internal_port_2 IP"
  default     = "192.168.10.10"
}

variable "k8s_internal_port_3_ip" {
  type        = string
  description = "k8s_internal_port_3 IP"
  default     = "192.168.10.20"
}

variable "k8s_internal_port_4_ip" {
  type        = string
  description = "k8s_internal_port_4 IP"
  default     = "192.168.10.30"
}

variable "k8s_internal_port_5_ip" {
  type        = string
  description = "k8s_internal_port_5 IP"
  default     = "192.168.10.40"
}

variable "ansible_server_name" {
  type        = string
  description = "Ansible Server 이름"
  default     = "ansible-server"
}

variable "controller_node_name" {
  type        = string
  description = "컨트롤러 노드 인스턴스 이름"
  default     = "controller-node"
}

variable "compute_node1_name" {
  type        = string
  description = "첫 번째 컴퓨트 노드 인스턴스 이름"
  default     = "compute-node1"
}

variable "compute_node2_name" {
  type        = string
  description = "두 번째 컴퓨트 노드 인스턴스 이름"
  default     = "compute-node2"
}

variable "storage_node_name" {
  type        = string
  description = "스토리지 노드 인스턴스 이름"
  default     = "storage-node"
}

variable "cloud_init_template" {
  type        = string
  description = "cloud_init 템플릿 파일 경로"
  default     = "cloud_init.tpl"
}
