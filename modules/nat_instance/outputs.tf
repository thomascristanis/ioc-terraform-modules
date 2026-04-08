output "instance_id" {
  value = aws_instance.nat.id
}

output "public_ip" {
  description = "Elastic IP address of the NAT instance."
  value       = aws_eip.nat.public_ip
}
