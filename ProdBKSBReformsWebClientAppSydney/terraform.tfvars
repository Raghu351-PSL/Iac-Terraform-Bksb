# --- Network Related Variables ---
vpc_id                  = "vpc-005358c415bc03d2a"
alb_prod_listener_sg_id = "sg-0b9c02e80606fdf25"
subnet_1_id             = "subnet-03dab5d928ae6d294"
subnet_2_id             = "subnet-0317393f66ed16f8d"

# --- ALB Listener ARNs ---
alb_prod_listener_arn = "arn:aws:elasticloadbalancing:ap-southeast-2:352515133004:listener/app/StageB-Live2-xnlTjSaDmFvj/92bd57624dc83d12/66a13a3fe0951914"
alb_test_listener_arn = "arn:aws:elasticloadbalancing:ap-southeast-2:352515133004:listener/app/StageB-Live2-xnlTjSaDmFvj/92bd57624dc83d12/7e8b0b8e400ffc12"

# --- Secrets Manager ARNs (Replace with your actual ARNs) ---
load_balancer_secret_arn      = "arn:aws:secretsmanager:ap-southeast-2:352515133004:secret:stage/loadbalancer/load_balancer_secret"
# --- ECS Cluster & Image Configuration ---
# This value typically comes from an output of another Terraform stack or a known AWS resource.
# You might need to use a data source for `aws_ecs_cluster` to get the actual cluster name.
ecs_cluster_name = "stage-bksb-live2reforms-cluster"

web_client_image       = "592311462240.dkr.ecr.eu-west-2.amazonaws.com/bksb/dev/bksblive2-reforms-web-clients:167-linux-x86_64"
xray_daemon_image      = "amazon/aws-xray-daemon:latest"
s3_cdn_private_bucket_name = "cdn.private.bksb-dev.co.uk"