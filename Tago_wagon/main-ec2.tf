# EC2 Resources

data "aws_ssm_parameter" "amzn2_linux" {
  name = "/aws/service/ami-amazon-linux-latest/amzn2-ami-hvm-x86_64-gp2"
}

module "web_front_end" {
  source = "./modules/web-front-end"
  //inputs del modulo
  app_port = var.app_port
  autoscaling_group_size = var.autoscale_group_size
  autoscaling_group_min_max = var.autoscale_group_min_max
  environment = var.environment
  instance_type = var.instance_type
  launch_template_ami = data.aws_ssm_parameter.amzn2_linux.value
  prefix = var.prefix
  publi_subnets_ids = module.vpc.public_subnets
  vpc_id = module.vpc.vpc_id
  user_data_contents = base64encode(templatefile("./templates/startup_script.tpl",{environment=var.environment}))
}

# Autoscaling Policies
resource "aws_autoscaling_policy" "scale_up" {
  name                   = "${var.prefix}-${var.environment}-scale-up"
  scaling_adjustment     = 1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = module.web_front_end.autoscaling_group_name
  policy_type            = "SimpleScaling"
}

resource "aws_autoscaling_policy" "scale_down" {
  name                   = "${var.prefix}-${var.environment}-scale-down"
  scaling_adjustment     = -1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = module.web_front_end.autoscaling_group_name
  policy_type            = "SimpleScaling"
}

# CloudWatch Alarms
resource "aws_cloudwatch_metric_alarm" "cpu_high" {
  alarm_name          = "${var.prefix}-${var.environment}-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "300"
  statistic           = "Average"
  threshold           = "75"
  alarm_description   = "This metric monitors ec2 cpu utilization"
  alarm_actions       = [aws_autoscaling_policy.scale_up.arn]

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.front_end.name
  }

  tags = {
    Name        = "${var.prefix}-${var.environment}-cpu-high-alarm"
    Environment = var.environment
  }
}

resource "aws_cloudwatch_metric_alarm" "cpu_low" {
  alarm_name          = "${var.prefix}-${var.environment}-cpu-low"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "300"
  statistic           = "Average"
  threshold           = "30"
  alarm_description   = "This metric monitors ec2 cpu utilization"
  alarm_actions       = [aws_autoscaling_policy.scale_down.arn]

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.front_end.name
  }

  tags = {
    Name        = "${var.prefix}-${var.environment}-cpu-low-alarm"
    Environment = var.environment
  }
}

# Load balancer resources
resource "aws_lb" "front_end" {
  name               = "${var.prefix}-nlb"
  internal           = false
  load_balancer_type = "network"
  subnets            = [for subnet in aws_subnet.public_subnets : subnet.id]
  security_groups    = [aws_security_group.nlb_sg.id]

  enable_deletion_protection = false

  tags = {
    Environment = var.environment
  }
}

resource "aws_lb_listener" "front_end" {
  load_balancer_arn = aws_lb.front_end.arn
  port              = var.app_port
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.front_end.arn
  }
}

resource "aws_lb_target_group" "front_end" {
  name     = "${var.prefix}-lb-tg"
  port     = var.app_port
  protocol = "TCP"
  vpc_id   = module.vpc.default_vpc_id
}

# Create a new ALB Target Group attachment
resource "aws_autoscaling_attachment" "front_end" {
  autoscaling_group_name = aws_autoscaling_group.front_end.id
  lb_target_group_arn    = aws_lb_target_group.front_end.arn
}

