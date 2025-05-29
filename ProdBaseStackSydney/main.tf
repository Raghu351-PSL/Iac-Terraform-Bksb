resource "aws_cloudwatch_log_group" "Live2VpcAllTraffic" {
  name              = "Live2VpcAllTraffic"
  retention_in_days = 731

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_iam_role" "Live2VpcFlowLogsRole" {
  name = "Live2VpcFlowLogsRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "vpc-flow-logs.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_policy" "Live2VpcFlowLogsRoleDefaultPolicy" {
  name = "Live2VpcFlowLogsRoleDefaultPolicy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "logs:CreateLogStream",
          "logs:DescribeLogStreams",
          "logs:PutLogEvents"
        ]
        Effect   = "Allow"
        Resource = aws_cloudwatch_log_group.Live2VpcAllTraffic.arn
      },
      {
        Action = "iam:PassRole"
        Effect = "Allow"
        Resource = aws_iam_role.Live2VpcFlowLogsRole.arn
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "AttachLive2VpcFlowLogsPolicy" {
  role       = aws_iam_role.Live2VpcFlowLogsRole.name
  policy_arn = aws_iam_policy.Live2VpcFlowLogsRoleDefaultPolicy.arn
}

resource "aws_vpc" "RootVpc" {
  cidr_block              = "10.10.0.0/16"
  enable_dns_hostnames    = true
  enable_dns_support      = true
  instance_tenancy        = "default"

  tags = {
    Name = "prod_vpc_live2_eu-west-2"
  }
}

resource "aws_ec2_flow_log" "RootVpcFlowLog" {
  log_group_name          = aws_cloudwatch_log_group.Live2VpcAllTraffic.name
  traffic_type            = "ALL"
  vpc_id                  = aws_vpc.RootVpc.id
  deliver_logs_permission_arn = aws_iam_role.Live2VpcFlowLogsRole.arn
}

resource "aws_internet_gateway" "IGW" {
  vpc_id = aws_vpc.RootVpc.id
}

resource "aws_vpc_gateway_attachment" "VPCIGwAttachment" {
  vpc_id             = aws_vpc.RootVpc.id
  internet_gateway_id = aws_internet_gateway.IGW.id
}

resource "aws_subnet" "FirewallSubnet" {
  vpc_id            = aws_vpc.RootVpc.id
  availability_zone = "eu-west-2a"
  cidr_block        = "10.10.2.0/24"

  tags = {
    Name = "ProdBaseStackLondon/FirewallSubnet"
  }
}

resource "aws_route_table" "FirewallSubnetRouteTable" {
  vpc_id = aws_vpc.RootVpc.id

  tags = {
    Name = "ProdBaseStackLondon/FirewallSubnet"
  }
}

resource "aws_route_table_association" "FirewallSubnetRouteTableAssociation" {
  route_table_id = aws_route_table.FirewallSubnetRouteTable.id
  subnet_id      = aws_subnet.FirewallSubnet.id
}

resource "aws_route" "FirewallSubnetDefaultRoute" {
  route_table_id         = aws_route_table.FirewallSubnetRouteTable.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.IGW.id

  depends_on = [aws_vpc_gateway_attachment.VPCIGwAttachment]
}

resource "aws_subnet" "NatSubnet" {
  vpc_id            = aws_vpc.RootVpc.id
  availability_zone = "eu-west-2a"
  cidr_block        = "10.10.1.0/24"

  tags = {
    Name = "ProdBaseStackLondon/NatSubnet"
  }
}

resource "aws_route_table" "NatSubnetRouteTable" {
  vpc_id = aws_vpc.RootVpc.id

  tags = {
    Name = "ProdBaseStackLondon/NatSubnet"
  }
}

resource "aws_route_table_association" "NatSubnetRouteTableAssociation" {
  route_table_id = aws_route_table.NatSubnetRouteTable.id
  subnet_id      = aws_subnet.NatSubnet.id
}

resource "aws_route" "NatSubnetFirewallRoute" {
  route_table_id         = aws_route_table.NatSubnetRouteTable.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.IGW.id

  depends_on = [aws_vpc_gateway_attachment.VPCIGwAttachment]
}

resource "aws_nat_gateway" "NatGateway" {
  subnet_id     = aws_subnet.NatSubnet.id
  allocation_id  = var.nat_gateway_allocation_id
}

resource "aws_networkfirewall_firewall_policy" "BaseFirewallPolicy" {
  name = "prodBaseFirewallPolicy"

  firewall_policy {
    stateless_default_actions          = ["aws:pass"]
    stateless_fragment_default_actions = ["aws:pass"]
  }
}

resource "aws_networkfirewall_firewall" "NATNetworkFirewall" {
  name               = "prodNetworkFirewall"
  firewall_policy_arn = aws_networkfirewall_firewall_policy.BaseFirewallPolicy.arn
  vpc_id             = aws_vpc.RootVpc.id

  subnet_mapping {
    subnet_id = aws_subnet.FirewallSubnet.id
  }
}

resource "aws_route_table" "FirewallIGWRouteTable" {
  vpc_id = aws_vpc.RootVpc.id
}

resource "aws_route" "FirewallIGWRoute" {
  route_table_id         = aws_route_table.FirewallIGWRouteTable.id
  destination_cidr_block = "10.10.1.0/24"
  gateway_id             = aws_internet_gateway.IGW.id
}

resource "aws_route_table_association" "FirewallGatewayRouteTableAssociation" {
  gateway_id      = aws_internet_gateway.IGW.id
  route_table_id  = aws_route_table.FirewallIGWRouteTable.id
}

resource "aws_resourcegroups_group" "ProductionInstances" {
  name        = "live2_prod_rg_eu-west-2"
  description = "CDK Managed Machines"

  resource_query {
    type  = "TAG_FILTERS_1_0"
    query = jsonencode({
      ResourceTypeFilters = [
        "AWS::EC2::Instance",
        "AWS::RDS::DBInstance"
      ],
      TagFilters = [
        {
          Key    = "Terraform-managed"
          Values = ["true"]
        }
      ]
    })
  }
}
