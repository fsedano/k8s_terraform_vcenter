

resource "rke_cluster" "cluster" {
  addons_include = [
    "https://raw.githubusercontent.com/kubernetes/dashboard/v2.0.0-beta8/aio/deploy/recommended.yaml"
  ]
  addon_job_timeout = 60
    network {
      plugin = "flannel"
    }
  services {
    kubelet {
      extra_args = {
        cloud-provider="vsphere",
        cloud-config="/etc/kubernetes/vsphere.conf"
      }
    }
    kube_api {
      extra_args = {
        cloud-provider="vsphere",
        cloud-config="/etc/kubernetes/vsphere.conf"
      }
    }

    kube_controller {
      extra_args = {
        cloud-provider="vsphere",
        cloud-config="/etc/kubernetes/vsphere.conf"
      }
    }

  }
  nodes {
    address = vsphere_virtual_machine.vm[0].default_ip_address
    user    = "root"
    role    = ["controlplane", "etcd"]
    ssh_key = file("ssh/id_rsa")
  }
  nodes {
    address = vsphere_virtual_machine.vm[1].default_ip_address
    user    = "root"
    role    = ["controlplane", "etcd"]
    ssh_key = file("ssh/id_rsa")
  }
  nodes {
    address = vsphere_virtual_machine.vm[2].default_ip_address
    user    = "root"
    role    = ["controlplane", "etcd"]
    ssh_key = file("ssh/id_rsa")
  }
  nodes {
    address = vsphere_virtual_machine.vm[3].default_ip_address
    user    = "root"
    role    = ["worker"]
    ssh_key = file("ssh/id_rsa")
  }
nodes {
    address = vsphere_virtual_machine.vm[4].default_ip_address
    user    = "root"
    role    = ["worker"]
    ssh_key = file("ssh/id_rsa")
  }


}

resource "local_file" "kube_cluster_yaml" {
  filename = "${path.root}/kube_config_cluster.yml"
  sensitive_content  = rke_cluster.cluster.kube_config_yaml
}


provider "vsphere" {
  user           = "administrator@vsphere.local"
  password       = "C1$c01234"
  vsphere_server = var.vsphere_server

  # If you have a self-signed cert
  allow_unverified_ssl = true
}


data "vsphere_datacenter" "dc" {
  name = var.datacenter
}

data "vsphere_datastore" "datastore" {
  name          = var.datastore
  datacenter_id = data.vsphere_datacenter.dc.id
}

data "vsphere_resource_pool" "pool" {
  name          = var.pool
  datacenter_id = data.vsphere_datacenter.dc.id
}

data "vsphere_network" "network" {
  name          = var.network
  datacenter_id = data.vsphere_datacenter.dc.id
}

data "vsphere_virtual_machine" "template" {
  name          = var.template_name
  datacenter_id = data.vsphere_datacenter.dc.id
}

data "vsphere_distributed_virtual_switch" "dvs" {
  name          = var.dvs
  datacenter_id = data.vsphere_datacenter.dc.id
}


resource "vsphere_virtual_machine" "vm" {
  name             = "kube16-t${count.index}"
  count = 5
  nested_hv_enabled = true
  resource_pool_id = data.vsphere_resource_pool.pool.id
  datastore_id     = data.vsphere_datastore.datastore.id

  num_cpus = 2
  memory   = 8192
  guest_id = "ubuntu64Guest"
  folder = "Kube-test"

connection {
    type     = "ssh"
    user     = "root"
    private_key = file("ssh/id_rsa")
    host = self.default_ip_address
  }
provisioner "remote-exec" {
  inline = [
    "mkdir /etc/kubernetes"
  ]
}
provisioner "file" {
    source = "vsphere_storage/vsphere.conf"
    destination = "/etc/kubernetes/vsphere.conf"
}


clone {
    template_uuid = data.vsphere_virtual_machine.template.id
    linked_clone = true
    customize {
      linux_options {
        host_name = "kube16-t${count.index}"
        domain    = "test.internal"
      }

      network_interface {
      }

      //ipv4_gateway = "192.168.30.254"
    }
}

  network_interface {
    network_id = data.vsphere_network.network.id
  }

  disk {
    label = "disk0"
    size  = var.disk_size
  }
}

/*
//https://computingforgeeks.com/how-to-deploy-ceph-storage-cluster-on-ubuntu-18-04-lts/
resource "vsphere_virtual_machine" "mon" {
  name             = "kube16-ceph-mon${count.index}"
  count = 3
  nested_hv_enabled = true
  resource_pool_id = data.vsphere_resource_pool.pool.id
  datastore_id     = data.vsphere_datastore.datastore.id

  num_cpus = 2
  memory   = 8192
  guest_id = "ubuntu64Guest"


clone {
    template_uuid = data.vsphere_virtual_machine.template.id
    linked_clone = true
    customize {
      linux_options {
        host_name = "kube16-ceph-mon${count.index}"
        domain    = "test.internal"
      }

      network_interface {
      }

    }
}

  network_interface {
    network_id = data.vsphere_network.network.id
  }

  disk {
    label = "disk0"
    size  = 32
  }
}

resource "vsphere_virtual_machine" "osd" {
  name             = "kube16-ceph-osd${count.index}"
  count = 3
  nested_hv_enabled = true
  resource_pool_id = data.vsphere_resource_pool.pool.id
  datastore_id     = data.vsphere_datastore.datastore.id

  num_cpus = 2
  memory   = 8192
  guest_id = "ubuntu64Guest"


clone {
    template_uuid = data.vsphere_virtual_machine.template.id
    linked_clone = true
    customize {
      linux_options {
        host_name = "kube16-ceph-osd${count.index}"
        domain    = "test.internal"
      }

      network_interface {
      }

    }
}

  network_interface {
    network_id = data.vsphere_network.network.id
  }

  disk {
    label = "disk0"
    size  = 32
  }
}

resource "vsphere_virtual_machine" "rgw" {
  name             = "kube16-ceph-rgw"
  nested_hv_enabled = true
  resource_pool_id = data.vsphere_resource_pool.pool.id
  datastore_id     = data.vsphere_datastore.datastore.id

  num_cpus = 2
  memory   = 8192
  guest_id = "ubuntu64Guest"


clone {
    template_uuid = data.vsphere_virtual_machine.template.id
    linked_clone = true
    customize {
      linux_options {
        host_name = "kube16-ceph-rgw"
        domain    = "test.internal"
      }

      network_interface {
      }

    }
}

  network_interface {
    network_id = data.vsphere_network.network.id
  }

  disk {
    label = "disk0"
    size  = 32
  }
}
resource "vsphere_virtual_machine" "admin" {
  name             = "kube16-ceph-admin"
  nested_hv_enabled = true
  resource_pool_id = data.vsphere_resource_pool.pool.id
  datastore_id     = data.vsphere_datastore.datastore.id

  num_cpus = 2
  memory   = 8192
  guest_id = "ubuntu64Guest"


clone {
    template_uuid = data.vsphere_virtual_machine.template.id
    linked_clone = true
    customize {
      linux_options {
        host_name = "kube16-ceph-admin"
        domain    = "test.internal"
      }

      network_interface {
      }

    }
}

  network_interface {
    network_id = data.vsphere_network.network.id
  }

  disk {
    label = "disk0"
    size  = 32
  }
}

output "ip_address" {
  value = vsphere_virtual_machine.vm[0].default_ip_address
}
*/