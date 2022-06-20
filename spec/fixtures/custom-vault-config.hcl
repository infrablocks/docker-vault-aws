storage "inmem" {}

listener "tcp" {
  tls_disable = 1
}

cluster_name = "TestVault"
disable_mlock = true
