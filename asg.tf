# Create Launch Template for Auto Scaling Group
resource "aws_launch_template" "terra-lc" {
  name                   = "Terra-LC"
  image_id               = data.aws_ami.terra-amazon-linux-2.id
  instance_type          = var.instance_type
  key_name               = aws_key_pair.terra-key.key_name
  vpc_security_group_ids = [aws_security_group.terra-web-access.id]
  user_data              = filebase64("install-apache.sh")
}

# Create Cloudwatch alarm to trigger Auto Scaling (Scale out)
resource "aws_cloudwatch_metric_alarm" "terra-alarm-up" {
  alarm_name          = "over_50_percent_cpu_utilization"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "60"
  statistic           = "Average"
  threshold           = "50"
  alarm_description   = "This metric monitors ec2 cpu utilization for scale up"
  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.terra-asg.name
  }

  alarm_actions = [aws_autoscaling_policy.terra-asg-up.arn]
}

# Create Cloudwatch alarm to trigger Auto Scaling (Scale in)
resource "aws_cloudwatch_metric_alarm" "terra-alarm-down" {
  alarm_name          = "under_50_percent_cpu_utilization"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "60"
  statistic           = "Average"
  threshold           = "70"
  alarm_description   = "This metric monitors ec2 cpu utilization for scale down"
  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.terra-asg.name
  }

  alarm_actions = [aws_autoscaling_policy.terra-asg-down.arn]
}

# Create step-scaling policy for Auto Scaling Group (Scale out)
resource "aws_autoscaling_policy" "terra-asg-up" {
  autoscaling_group_name    = aws_autoscaling_group.terra-asg.name
  name                      = "scale-up"
  adjustment_type           = "ChangeInCapacity"
  policy_type               = "StepScaling"
  estimated_instance_warmup = 30


  step_adjustment {
    scaling_adjustment          = 1
    metric_interval_lower_bound = 0
    metric_interval_upper_bound = 20
  }

  step_adjustment {
    scaling_adjustment          = 2
    metric_interval_lower_bound = 20
  }

}

# Create step-scaling policy for Auto Scaling Group (Scale in)
resource "aws_autoscaling_policy" "terra-asg-down" {
  autoscaling_group_name    = aws_autoscaling_group.terra-asg.name
  name                      = "scale-down"
  adjustment_type           = "ChangeInCapacity"
  policy_type               = "StepScaling"
  estimated_instance_warmup = 30

  step_adjustment {
    scaling_adjustment          = -2
    metric_interval_upper_bound = -20
  }

  step_adjustment {
    scaling_adjustment          = -1
    metric_interval_lower_bound = -20
    metric_interval_upper_bound = 0
  }
}

# Create Auto Scaling Group 
resource "aws_autoscaling_group" "terra-asg" {
  name                      = "Terra-ASG"
  vpc_zone_identifier       = [aws_subnet.private-a.id, aws_subnet.private-b.id]
  min_size                  = 2
  max_size                  = 4
  desired_capacity          = 2
  health_check_grace_period = 300
  health_check_type         = "ELB"
  launch_template {
    id      = aws_launch_template.terra-lc.id
    version = "$Latest"
  }
  lifecycle {
    create_before_destroy = true
    ignore_changes        = [load_balancers, target_group_arns]
  }
}

# Attach Application Load Balancer to Auto Scaling Group
resource "aws_autoscaling_attachment" "terra-asg" {
  autoscaling_group_name = aws_autoscaling_group.terra-asg.id
  lb_target_group_arn    = aws_lb_target_group.terra-tg.arn
}

