output "alb_dns_name" {
  value       = module.webserver_cluster.alb_dns_name
  description = "The domain name of the load balancer"
}

output "asg_name" {
  value       = module.webserver_cluster.asg_name
  description = "The name of the Auto Scaling Group"
}

output "instance_security_group_id" {
  value       = module.webserver_cluster.instance_security_group_id
  description = "Security group ID attached to cluster instances"
}
