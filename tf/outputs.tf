
# + Outputs
output "public_ip" {
  value = aws_instance.mi_instancia.public_ip
}

output "instance_id" {
  value = aws_instance.mi_instancia.id
}
