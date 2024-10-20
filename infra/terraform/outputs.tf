output "lb_dns_name" {
  description = "The DNS name of the Application LB"
  value       = aws_lb.this.dns_name
}
