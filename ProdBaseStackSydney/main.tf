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

resource "aws_iam_policy" "NewLive2VpcFlowLogsRoleDefaultPolicy" {
  name = "NewLive2VpcFlowLogsRoleDefaultPolicy"  # Updated name

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
        Resource = aws_cloudwatch_log_group.NewLive2VpcAllTraffic.arn  # Updated resource reference
      },
      {
        Action = "iam:PassRole"
        Effect   = "Allow"
        Resource = aws_iam_role.NewLive2VpcFlowLogsRole.arn  # Updated resource reference
      }
    ]
  })
}
resource "aws_iam_role_policy_attachment" "NewLive2VpcFlowLogsRoleAttachment" {
  role       = aws_iam_role.NewLive2VpcFlowLogsRole.name  # Updated resource reference
  policy_arn = aws_iam_policy.NewLive2VpcFlowLogsRoleDefaultPolicy.arn  # Updated resource reference
}
resource "aws_vpc" "RootVpc" {
  cidr_block              = "10.20.0.0/16"  # New CIDR block
  enable_dns_hostnames    = true
  enable_dns_support      = true
  instance_tenancy        = "default"

  tags = {
    Name = "prod_vpc_live2_eu-west-2_new"  # Updated name
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
  cidr_block        = "10.20.2.0/24"  # New CIDR block

  tags = {
    Name = "ProdBaseStackLondon/FirewallSubnet_New"  # Updated name
  }
}

resource "aws_route_table" "FirewallSubnetRouteTable" {
  vpc_id = aws_vpc.RootVpc.id

  tags = {
    Name = "ProdBaseStackLondon/FirewallSubnet_New"  # Updated name
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
  cidr_block        = "10.20.1.0/24"  # New CIDR block

  tags = {
    Name = "ProdBaseStackLondon/NatSubnet_New"  # Updated name
  }
}

resource "aws_route_table" "NatSubnetRouteTable" {
  vpc_id = aws_vpc.RootVpc.id

  tags = {
    Name = "ProdBaseStackLondon/NatSubnet_New"  # Updated name
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
  destination_cidr_block = "10.20.1.0/24"  # Updated CIDR block
  gateway_id             = aws_internet_gateway.IGW.id
}

resource "aws_route_table_association" "FirewallGatewayRouteTableAssociation" {
  gateway_id      = aws_internet_gateway.IGW.id
  route_table_id  = aws_route_table.FirewallIGWRouteTable.id
}

resource "aws_resourcegroups_group" "ProductionInstances" {
  name        = "live2_prod_rg_eu-west-2_new"  # Updated name
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