output "vpc_id" {
  value = aws_vpc.main.id
}

output "public_subnet_id" {
  value = aws_subnet.public.id
}

output "ec2_instance_id" {
  value = aws_instance.web.id
}

output "ec2_public_ip" {
  value = aws_instance.web.public_ip
}

output "website_url" {
  value = "http://${aws_instance.web.public_ip}"
}

output "s3_bucket_name" {
  value = aws_s3_bucket.project.bucket
}

output "backup_vault_name" {
  value = aws_backup_vault.main.name
}