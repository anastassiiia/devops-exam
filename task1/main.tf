# 1. Віртуальна приватна хмара (VPC)
resource "digitalocean_vpc" "vpc" {
  name     = "chuikova-vpc"
  region   = "fra1"
  ip_range = "10.10.10.0/24"
}

# 2. Сховище для обʼєктів (Бакет)
resource "digitalocean_spaces_bucket" "bucket" {
  name   = "chuikova-bucket-${random_id.bucket_suffix.hex}"
  region = "fra1"
}

resource "random_id" "bucket_suffix" {
  byte_length = 4
}

# 3. Віртуальна машина (Droplet)
resource "digitalocean_droplet" "node" {
  name     = "chuikova-node"
  region   = "fra1"
  size     = "s-2vcpu-4gb"
  image    = "ubuntu-24-04-x64"
  vpc_uuid = digitalocean_vpc.vpc.id
  ssh_keys = [digitalocean_ssh_key.ansible_key.id]
}

# 4. Налаштування фаєрволу
resource "digitalocean_firewall" "firewall" {
  name = "chuikova-firewall"
  droplet_ids = [digitalocean_droplet.node.id]

  dynamic "inbound_rule" {
    for_each = ["22", "80", "443", "8000", "8001", "8002", "8003"]
    content {
      protocol         = "tcp"
      port_range       = inbound_rule.value
      source_addresses = ["0.0.0.0/0", "::/0"]
    }
  }

  outbound_rule {
    protocol              = "tcp"
    port_range            = "1-65535"
    destination_addresses = ["0.0.0.0/0", "::/0"]
  }

  outbound_rule {
    protocol              = "udp"
    port_range            = "1-65535"
    destination_addresses = ["0.0.0.0/0", "::/0"]
  }
}

# 5. Твій публічний SSH ключ
resource "digitalocean_ssh_key" "ansible_key" {
  name       = "chuikova-ansible-key"
  public_key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOerO5FvpcLEPsXYIW6/BJbq8Cdy95wfEhd1Sa5BZN5D admin@Anastasia"
}
