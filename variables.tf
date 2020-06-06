variable vsphere_server {
  type = string
  default = "192.168.20.101"
}

variable datacenter {
  type = string
  default = "Datacenter1"
}

variable datastore {
  type = string
  default = "datastore1"
}

variable network {
  type = string
  default = "DS_VL20"
}

variable pool {
  type = string
  default = "Pool1"
}

variable dvs {
  type = string
  default = "DSwitch1"
}

variable template_name {
  type = string
  default = "ubuntu16_k8s"
}

variable disk_size {
  type = number
  default = 16
}
