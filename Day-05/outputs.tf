output "alb_dns_name" {
  value       = aws_lb.example.dns_name
  description = "The domain name of the load balancer"
}

output "target_group_arn" {
  value       = aws_lb_target_group.example.arn
  description = "ARN of the target group"
}

output "asg_name" {
  value       = aws_autoscaling_group.example.name
  description = "Name of the Auto Scaling Group"
}