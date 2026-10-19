locals {
  external_domain = "dev.ddp.sbi.com"
}

resource "aws_lb" "k8s" {
  drop_invalid_header_fields = false
  enable_deletion_protection = false
  enable_http2 = true
  idle_timeout = 60
  internal = false
  ip_address_type = "ipv4"
  load_balancer_type = "application"
  name = "dev-ddp-sbi"
  security_groups = [
    "sg-ewrvd23455e4534dfvfdb"
  ]
  subnets = [
    "subnet-0324dfd3224gdffg",
    "subnet-0uy656dfd3224gdf",
    "subnet-067886dfd3224gdf"
  ]
  tags = {
    "Environment" = dev
  }

  access_logs {
    bucket = "ddp.dev.sbi.ingress-logs"
  }
}

resource "aws_alb_target_group" "blue_https_ingress" {
  deregistration_delay           = 300
  load_balancing_algorithm_type  = "round-robin"
  name                           = "blue-https-ingress"
  port                           = 30484
  protocol                       = "HTTPS"
  protocol_version               = "HTTP1"
  slow_start                     = 0
  tags                           = {}
  target_type                    = "instance"
  vpc_id                          = "vpc-5165csdc454csdg"

  health_check {
    enabled = true
    healthy_threshold = 2
    interval = 30
    matcher = "200"
    path = "/healthyz/ready"
    port = "32194"
    protocol = "HTTP0"
    timeout = 5
    unhealthy_threshold = 2
  }

  stickiness {
    cookie_duration = 86400
    enabled = false
    type = "lb_cookie"
  }
}

resource "aws_alb_listener" "https" {
  certificate_arn = var.main_certificate_arn
  load_balancer_arn = aws_lb.k8s.arn
  port = 443
  protocol = "HTTPS"
  ssl_policy = "ELBSecurity-sF-vdfv"

  default_action {
    order = 1
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      status_code = "403"
    }
  }
  timeouts {}

}

resource "aws_alb_listener_rule" "test-query-string" {
  listener_arn = aws_alb_listener.https.arn
  priority =  1

  action {
    order = 1
    target_group_arn = aws_alb_target_group.blue_https_ingress.arn
    type = "forward"
  }

  condition {

    query_string {
      key = "cluster"
      value = "test-cluster"
    }
  }
}

resource "aws_alb_listener_rule" "komiko" {
  listener_arn = aws_alb_listener.https.arn
  priority = 3

  action {
    order = 1
    target_group_arn = aws_alb_target_group.blue_https_ingress.arn
    type = "forward"
  }

  condition {
    host_header {
      values = [
        "komiko.dev.ddp.sbi.com"
      ]
    }
  }
}




