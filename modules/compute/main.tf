variable "security_group" {
  description = "The security groups assigned to the Jenkins server"
}

variable "public_subnet" {
  description = "The public subnet IDs assigned to the Jenkins server"
}

data "aws_ami" "ubuntu" {
  most_recent = "true"

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"]
}

resource "aws_instance" "jenkins_server" {
  ami                    = data.aws_ami.ubuntu.id
  subnet_id              = var.public_subnet
  instance_type          = "t2.micro"
  vpc_security_group_ids = [var.security_group]
  key_name               = aws_key_pair.tutorial_kp.key_name
  user_data              = file("${path.module}/install_jenkins.sh")

  tags = {
    Name = "jenkins_server"
  }
}

resource "aws_key_pair" "tutorial_kp" {
  key_name   = "tutorial_kp"
  public_key = file("${path.module}/tutorial_kp.pub")
}

resource "aws_eip" "jenkins_eip" {
  instance = aws_instance.jenkins_server.id
  vpc      = true

  tags = {
    Name = "jenkins_eip"
  }
}

resource "null_resource" "setupjenkins" {
  depends_on = [
    aws_instance.jenkins_server,
    aws_eip.jenkins_eip,
  ]


  //
  provisioner "local-exec" {
    command = "ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -u ubuntu --private-key tutorial_kp.pem -i '${aws_eip.jenkins_eip.public_ip},' playbooks/main.yml"
  }
}
