# ==========================================
# EC2 PUBLIC IP
# ==========================================

output "public_ip" {
  value = aws_instance.k3s_server.public_ip
}

# ==========================================
# EC2 PUBLIC DNS
# ==========================================

output "public_dns" {
  value = aws_instance.k3s_server.public_dns
}

# ==========================================
# INSTANCE ID
# ==========================================

output "instance_id" {
  value = aws_instance.k3s_server.id
}