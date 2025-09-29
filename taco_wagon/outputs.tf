output "public_nlb_dns" {
  value = aws_lb.front_end.dns_name
}