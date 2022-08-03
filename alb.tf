# Create Target Group
resource "aws_lb_target_group" "terra-tg" {
  name     = "Terra-TG"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.terra-vpc.id
}

# Create Application Load Balancer
resource "aws_lb" "terra-alb" {
  name               = "Terra-ALB"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.terra-web-access.id]
  subnets            = [aws_subnet.public-a.id, aws_subnet.public-b.id]
}

# Attach Target to Load Balancer
resource "aws_lb_listener" "lb_listener_http" {
  load_balancer_arn = aws_lb.terra-alb.arn
  port              = "80"
  protocol          = "HTTP"
  default_action {
    target_group_arn = aws_lb_target_group.terra-tg.arn
    type             = "forward"
  }
}

output "alb_dns_name" {
  value = aws_lb.terra-alb.dns_name
}