output "instance_id" {
    value = aws_instance.my_instance.id
    description = "ID of the ec2 instance"
}

output "public_ip" {
    value = aws_instance.my_instance.public_ip
    description = "IP Address of the instance"
  
}
                                                                                                                                                                                                                                                                                                                                            