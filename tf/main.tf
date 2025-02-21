
provider "aws" {
  region = var.region
}

resource "aws_key_pair" "apache_server_ssh" {
  key_name   = "neikapKey"
  public_key = file("clave.key.pub")
  tags = {
    Name = "neikapKey"
  }
}
