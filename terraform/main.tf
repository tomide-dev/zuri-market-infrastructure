# ==================================
# DATA SOURCES
# ==================================

data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# ==========================================
# UBUNTU 24.04 AMI
# ==========================================
data "aws_ami" "ubuntu" {
  most_recent = true

  owners = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }
}

# ===================================
# SECURITY GROUP
# ===================================
resource "aws_security_group" "k3s_sg" {
  name        = "${var.project_name}-sg"
  description = "Security group for k3s server"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "k3s API"
    from_port   = 6443
    to_port     = 6443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "NodePort Services"
    from_port   = 30000
    to_port     = 32767
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# ==========================================
# IAM ROLE
# ==========================================

resource "aws_iam_role" "ec2_role" {

  name = "${var.project_name}-ec2-role"

  assume_role_policy = jsonencode({

    Version = "2012-10-17"

    Statement = [

      {
        Effect = "Allow"

        Principal = {
          Service = "ec2.amazonaws.com"
        }

        Action = "sts:AssumeRole"
      }

    ]
  })
}

# ==========================================
# SECTION 5 - AWS SECRETS MANAGER
# ==========================================

resource "aws_secretsmanager_secret" "zurimarket_secret" {

  name        = "zurimarket-prod"
  description = "Application secrets for Zuri Market"
}

resource "aws_secretsmanager_secret_version" "zurimarket_secret_value" {

  secret_id = aws_secretsmanager_secret.zurimarket_secret.id

  secret_string = jsonencode({
    API_SECRET_KEY = var.api_secret_key
    STORE_NAME     = var.store_name
  })
}

# ==========================================
# SECRETS MANAGER POLICY
# ==========================================

resource "aws_iam_role_policy" "secrets_policy" {

  name = "${var.project_name}-secrets-policy"

  role = aws_iam_role.ec2_role.id

  policy = jsonencode({

    Version = "2012-10-17"

    Statement = [

      {
        Effect = "Allow"

        Action = [

          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret",
          "secretsmanager:ListSecrets"

        ]

        Resource = "*"
      }

    ]
  })
}

# ==========================================
# INSTANCE PROFILE
# ==========================================

resource "aws_iam_instance_profile" "ec2_profile" {

  name = "${var.project_name}-instance-profile"

  role = aws_iam_role.ec2_role.name

}

# ==========================================
# EC2 INSTANCE
# ==========================================

resource "aws_instance" "k3s_server" {

  ami           = data.aws_ami.ubuntu.id
  instance_type = var.instance_type

  subnet_id = data.aws_subnets.default.ids[0]

  vpc_security_group_ids = [
    aws_security_group.k3s_sg.id
  ]

  key_name = var.key_pair_name

  iam_instance_profile = aws_iam_instance_profile.ec2_profile.name

  user_data = file("${path.module}/userdata.sh")

  tags = {
    Name = "${var.project_name}-k3s-server"
  }
}