output "public_ip" {
  description = "Elastic IP of the New API instance"
  value       = aws_eip.newapi.public_ip
}

output "ssh_command" {
  description = "SSH command to reach the instance"
  value       = "ssh ubuntu@${aws_eip.newapi.public_ip}"
}

output "newapi_url" {
  description = "URL to open New API (once containers are up, may take a minute or two after apply)"
  value       = var.domain_name != "" ? "https://${var.domain_name}" : "http://${aws_eip.newapi.public_ip}"
}
