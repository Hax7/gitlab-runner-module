source "amazon-ebs" "amazon-linux-docker" {
  ami_name      = "amazon-linux-docker-{{timestamp}}"
  instance_type = "t2.micro"
  region        = "us-east-1"
  subnet_id     = "subnet-0688fba8e0845e1dd"
  source_ami_filter {
    filters = {
      name                = "al2023-ami-2023.*-x86_64"
      root-device-type    = "ebs"
      virtualization-type = "hvm"
    }
    most_recent = true
    owners      = ["amazon"]
  }
  ssh_username = "ec2-user"
}

build {
  sources = [
    "source.amazon-ebs.amazon-linux-docker"
  ]

  provisioner "shell" {
    inline = [
      "sudo yum update -y",
      "sudo yum install docker -y",
      "sudo usermod -a -G docker ec2-user",
      "sudo systemctl start docker",
      "sudo systemctl enable docker"
    ]
  }
}
