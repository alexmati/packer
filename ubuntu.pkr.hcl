packer {
  required_plugins {
    amazon = {
      version = ">= 1.8.0"
      source  = "github.com/hashicorp/amazon"
    }
  }
}

source "amazon-ebs" "hardened-ubuntu" {
  assume_role {
    role_arn = "arn:aws:iam::037490752993:role/packer-build-role"
  }

  ami_name      = "packer-ubuntu-22.04"
  instance_type = "t3.micro"
  region        = "eu-west-2"

  communicator         = "ssh"
  ssh_username         = "ubuntu"
  ssh_interface        = "session_manager"
  iam_instance_profile = "PackerExecutorRole"

  source_ami_filter {
    filters = {
      name                = "ubuntu/images/*ubuntu-jammy-22.04-amd64-server-*"
      root-device-type    = "ebs"
      virtualization-type = "hvm"
    }
    most_recent = true
    owners      = ["099720109477"]
  }
}

build {
  name = "hardened-ubuntu-22.04"
  sources = [
    "source.amazon-ebs.hardened_ubuntu_22_04"
  ]

  provisioner "ansible" {
    use_proxy               = false
    playbook_file           = "./ansible/ubuntu.yml"
    inventory_file_template = "{{ .HostAlias }} ansible_host={{ .ID }} ansible_user={{ .User }} ansible_ssh_common_args='-o StrictHostKeyChecking=no -o ProxyCommand=\"sh -c \\\"aws ssm start-session --target %h --document-name AWS-StartSSHSession --parameters portNumber=%p\\\"\"'\n"
  }
}
