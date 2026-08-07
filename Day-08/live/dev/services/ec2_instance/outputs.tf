output "instance_id" {
    value = module.ec2_instance.instance_id
    description = "Id of the instance"
  
}

output "public_ip" {
    value = module.ec2_instance.public_ip
    description = "public IP of the instance"
  
}
