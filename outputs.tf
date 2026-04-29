output "jenkins_public_ip" {
  value = aws_instance.jenkins.public_ip
}

output "app_public_ip" {
  value = aws_instance.app.public_ip
}

output "app_url" {
  value = "http://${aws_instance.app.public_ip}"
}

output "jenkins_url" {
  value = "http://${aws_instance.jenkins.public_ip}:8080"
}

output "mongodb_private_ip" {
  value = aws_instance.mongodb.private_ip
}