output "instance_id" {
  value = aws_instance.web.id
}

output "instance_type" {
  value = aws_instance.web.instance_type
}

output "public_ip" {
  value = aws_instance.web.public_ip
}
