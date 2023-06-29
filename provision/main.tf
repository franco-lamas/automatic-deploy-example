# Configure the AWS Provider

provider "aws" {
  access_key = var.access_key 
  secret_key = var.secret_key 
  region     = var.region
}

  resource "aws_key_pair" "deployer" {
  key_name   = "deployer-key"
  public_key = file("./aws_key.pub")
  }

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

resource "aws_instance" "web" {


  ami           = data.aws_ami.ubuntu.id
  //ami = "" // NO ES ELEGANTE!
  instance_type = "t2.micro"
  key_name = aws_key_pair.deployer.key_name
  

  network_interface {
    delete_on_termination = false
    network_interface_id  = aws_network_interface.myinstance.id
    device_index          = 0
  }  
  tags = {
    Name = "web-server"
  }
  provisioner "local-exec" {
    command = "rm inventory && echo '[pve-ubuntu]' >> inventory && echo '${aws_instance.web.public_ip}' >> inventory && sleep 120 && ansible-playbook -u ubuntu --private-key aws_key init-image.yml "
  }
}



output "public_ip" {
  value       = aws_instance.web.public_ip
}

