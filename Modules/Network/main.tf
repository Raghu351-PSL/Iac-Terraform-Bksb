resource "aws_logs_log_group" "live2_vpc_all_traffic" {
  name              = "Live2VpcAllTraffic"
  retention_in_days = 731
}

resource "aws_iam_role" "live2_vpc_flow_logs_role" {
  name = "Live2VpcFlowLogsRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = "sts:AssumeRole",
      Principal = {
        Service = "vpc-flow-logs.amazonaws.com"
      },
      Effect = "Allow",
      Sid    = ""
    }]
  })
}

resource "aws_iam_policy" "live2_vpc_flow_logs_role_policy" {
  name = "Live2VpcFlowLogsRoleDefaultPolicy"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = [
          "logs:CreateLogStream",
          "logs:DescribeLogStreams",
          "logs:PutLogEvents"
        ],
        Effect   = "Allow",
        Resource = aws_logs_log_group.live2_vpc_all_traffic.arn
      },
      {
        Action   = "iam:PassRole",
        Effect   = "Allow",
        Resource = aws_iam_role.live2_vpc_flow_logs_role.arn
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "live2_vpc_flow_logs_role_policy_attachment" {
  role       = aws_iam_role.live2_vpc_flow_logs_role.name
  policy_arn = aws_iam_policy.live2_vpc_flow_logs_role_policy.arn
}
resource "aws_vpc" "root_vpc" {
  cidr_block           = var.cidr_block
  enable_dns_hostnames = true
  enable_dns_support   = true
  instance_tenancy     = "default"

  tags = {
    Name = "prod_vpc_live2_eu-west-2"
  }
}
resource "aws_flow_log" "root_vpc_all_traffic" {
  vpc_id               = aws_vpc.root_vpc.id
  traffic_type         = "ALL"
  log_destination_type = "cloud-watch-logs"
  log_destination      = aws_logs_log_group.live2_vpc_all_traffic.arn
  iam_role_arn         = aws_iam_role.live2_vpc_flow_logs_role.arn

  tags = {
    Name = "prod_vpc_live2_eu-west-2"
  }
}
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.root_vpc.id
}
resource "aws_subnet" "firewall_subnet" {
  vpc_id            = aws_vpc.root_vpc.id
  cidr_block        = var.subnet_cidr_block
  availability_zone = var.availability_zone

  tags = {
    Name = "ProdBaseStackLondon/FirewallSubnet"
  }
}

resource "aws_route_table" "firewall_subnet_route_table" {
  vpc_id = aws_vpc.root_vpc.id

  tags = {
    Name = "ProdBaseStackLondon/FirewallSubnet"
  }
}

resource "aws_route_table_association" "firewall_subnet_route_table_association" {
  subnet_id      = aws_subnet.firewall_subnet.id
  route_table_id = aws_route_table.firewall_subnet_route_table.id
}

resource "aws_route" "firewall_subnet_default_route" {
  route_table_id         = aws_route_table.firewall_subnet_route_table.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw.id
}

resource "aws_subnet" "nat_subnet" {
  vpc_id            = aws_vpc.root_vpc.id
  cidr_block        = var.subnet_cidr_block
  availability_zone = var.availability_zone

  tags = {
    Name = "ProdBaseStackLondon/NatSubnet"
  }
}

resource "aws_route_table" "nat_subnet_route_table" {
  vpc_id = aws_vpc.root_vpc.id

  tags = {
    Name = "ProdBaseStackLondon/NatSubnet"
  }
}

resource "aws_route_table_association" "nat_subnet_route_table_association" {
  subnet_id      = aws_subnet.nat_subnet.id
  route_table_id = aws_route_table.nat_subnet_route_table.id
}

resource "aws_nat_gateway" "nat_gateway" {
  subnet_id     = aws_subnet.nat_subnet.id
  allocation_id = var.nat_allocation_id
}

resource "aws_network_firewall_firewall_policy" "base_firewall_policy" {
  firewall_policy = {
    stateless_default_actions = ["aws:pass"]
    stateless_fragment_default_actions = ["aws:pass"]
  }
  firewall_policy_name = "prodBaseFirewallPolicy"
}

resource "aws_network_firewall_firewall" "nat_network_firewall" {
  firewall_name        = "prodNetworkFirewall"
  firewall_policy_arn  = aws_network_firewall_firewall_policy.base_firewall_policy.arn
  vpc_id               = aws_vpc.root_vpc.id
  subnet_mappings = [{
    subnet_id = aws_subnet.firewall_subnet.id
  }]
}

resource "aws_route_table" "firewall_igw_route_table" {
  vpc_id = aws_vpc.root_vpc.id
}

resource "aws_route" "firewall_igw_route" {
  route_table_id         = aws_route_table.firewall_igw_route_table.id
  destination_cidr_block = var.subnet_cidr_block
  vpc_endpoint_id        = aws_network_firewall_firewall.nat_network_firewall.endpoint_ids[0]
}

resource "aws_ec2_gateway_route_table_association" "firewall_gateway_route_table_association" {
  gateway_id     = aws_internet_gateway.igw.id
  route_table_id = aws_route_table.firewall_igw_route_table.id
}

resource "aws_resourcegroups_group" "production_instances" {
  name        = "live2_prod_rg_eu-west-2"
  description = "CDK Managed Machines"

  resource_query {
    query = jsonencode({
      ResourceTypeFilters = ["AWS::EC2::Instance", "AWS::RDS::DBInstance"]
      TagFilters = [{
        Key    = "cdk-managed"
        Values = ["true"]
      }]
    })
  }
}
