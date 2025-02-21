
# + Instancia EC2
resource "aws_instance" "mi_instancia" {
  ami                        = "ami-0866a3c8686eaeeba"
  instance_type              = "t2.micro"
  key_name                   = aws_key_pair.apache_server_ssh.key_name
  subnet_id                  = aws_subnet.mi_subred_publica.id
  vpc_security_group_ids     = [aws_security_group.sg.id]
  associate_public_ip_address = true

  # Ejecuto mi user_data
  user_data = <<-EOF
    #!/bin/bash

    # Actualizo e instalo docker
    sudo apt-get update -y
    sudo apt-get install docker.io -y

    # Inicio el servicio de docker
    sudo systemctl start docker
    sudo systemctl enable docker

    # Clono el repositorio que contiene mi dockerfile
    sudo apt-get install git -y
    sudo git clone https://github.com/Inereaa/PYneikap.git /var/www/html

    # Construyo la imagen del dockerfile
    cd /var/www/html
    sudo docker build -t apache-server .

    # Ejecuto el contenedor y le pongo un nombre
    sudo docker run -d -p 80:80 -p 443:443 --name neikap apache-server

  EOF

  tags = {
    Name = "MiInstanciaEC2"
  }
}
