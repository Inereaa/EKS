
# + VPC
resource "aws_vpc" "mi_vpc" {
  cidr_block = var.vpc_cidr

  tags = {
    Name = "MiVPC"
  }
}

# + Subred pública
resource "aws_subnet" "mi_subred_publica" {
  vpc_id                  = aws_vpc.mi_vpc.id
  cidr_block              = var.public_subnet_cidr
  availability_zone       = "${var.region}a"
  map_public_ip_on_launch = true

  tags = {
    Name = "MiSubredPublica"
  }
}

# + Gateway de internet
resource "aws_internet_gateway" "mi_gateway" {
  vpc_id = aws_vpc.mi_vpc.id

  tags = {
    Name = "MiGateway"
  }
}

# + Tabla de rutas
resource "aws_route_table" "mi_tabla_rutas" {
  vpc_id = aws_vpc.mi_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.mi_gateway.id
  }

  tags = {
    Name = "MiTablaRutas"
  }
}

# Asociación de la tabla de rutas con la subred
resource "aws_route_table_association" "mi_asociacion_tabla" {
  subnet_id      = aws_subnet.mi_subred_publica.id
  route_table_id = aws_route_table.mi_tabla_rutas.id
}
