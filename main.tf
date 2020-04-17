
resource "rke_cluster" "cluster" {
  addons_include = [
    "https://raw.githubusercontent.com/kubernetes/dashboard/v2.0.0-beta8/aio/deploy/recommended.yaml"
  ]
  addon_job_timeout = 60
  network {
    plugin = "flannel"
  }
  nodes {
    address = vsphere_virtual_machine.vm[0].default_ip_address
    user    = "root"
    role    = ["controlplane", "worker", "etcd"]
    ssh_key = file("~/.ssh/id_rsa")
  }
  nodes {
    address = vsphere_virtual_machine.vm[1].default_ip_address
    user    = "root"
    role    = ["controlplane", "worker", "etcd"]
    ssh_key = file("~/.ssh/id_rsa")
  }
  nodes {
    address = vsphere_virtual_machine.vm[2].default_ip_address
    user    = "root"
    role    = ["controlplane", "worker", "etcd"]
    ssh_key = file("~/.ssh/id_rsa")
  }
  nodes {
    address = vsphere_virtual_machine.vm[3].default_ip_address
    user    = "root"
    role    = ["worker"]
    ssh_key = file("~/.ssh/id_rsa")
  }
nodes {
    address = vsphere_virtual_machine.vm[4].default_ip_address
    user    = "root"
    role    = ["worker"]
    ssh_key = file("~/.ssh/id_rsa")
  }
nodes {
    address = vsphere_virtual_machine.vm[5].default_ip_address
    user    = "root"
    role    = ["worker"]
    ssh_key = file("~/.ssh/id_rsa")
  }
nodes {
    address = vsphere_virtual_machine.vm[6].default_ip_address
    user    = "root"
    role    = ["worker"]
    ssh_key = file("~/.ssh/id_rsa")
  }

}

resource "local_file" "kube_cluster_yaml" {
  filename = "${path.root}/kube_config_cluster.yml"
  sensitive_content  = rke_cluster.cluster.kube_config_yaml
}


provider "vsphere" {
  user           = "administrator@vsphere.local"
  password       = "C1$c01234"
  #vsphere_server = "192.168.20.202"
  vsphere_server = var.vsphere_server

  # If you have a self-signed cert
  allow_unverified_ssl = true
}


data "vsphere_datacenter" "dc" {
  name = "DatacenterLM"
}

data "vsphere_datastore" "datastore" {
  name          = "Datastore"
  datacenter_id = data.vsphere_datacenter.dc.id
}

data "vsphere_resource_pool" "pool" {
  name          = "Pool1"
  datacenter_id = data.vsphere_datacenter.dc.id
}

data "vsphere_network" "network" {
  name          = "PG_VL30"
  datacenter_id = data.vsphere_datacenter.dc.id
}

data "vsphere_virtual_machine" "template" {
  name          = "ubuntu16"
  datacenter_id = data.vsphere_datacenter.dc.id
}

data "vsphere_distributed_virtual_switch" "dvs" {
  name          = "DSTrunk"
  datacenter_id = data.vsphere_datacenter.dc.id
}


resource "vsphere_virtual_machine" "vm" {
  name             = "kube16-t${count.index}"
  count = 7
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
    size  = 32
  }
}

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