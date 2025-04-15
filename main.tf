provider "aws" {
  region = "us-east-1"
}

# --- Data Sources ---

data "aws_default_subnet" "default_subnet_az_a" {
  availability_zone = "us-east-1a"
}

# Find the VPC ID associated with the default subnet
data "aws_vpc" "default" {
  default = true
}

# --- Security Group ---

resource "aws_security_group" "allow_web_traffic" {
  name        = "allow-web-traffic-sg"
  description = "Allow HTTP and HTTPS inbound traffic"
  vpc_id      = data.aws_vpc.default.id # Use the default VPC ID

  ingress = {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "HTTP from anywhere"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Allow from any IP address
  }

  ingress {
    description = "HTTPS from anywhere"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Allow from any IP address
  }

  # Allow all outbound traffic (standard practice)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1" # -1 means all protocols
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "Allow-Web-Traffic-SG"
  }
}

# --- Instance 1 ---

resource "aws_instance" "instance_1" {
  # IMPORTANT: Verify this AMI ID is still valid and appropriate for your needs in us-east-1
  ami           = "ami-084568db4383264d4"
  instance_type = "t2.micro"
  subnet_id     = data.aws_default_subnet.default_subnet_az_a.id

  # Associate the instance with the security group created above
  # Note: vpc_security_group_ids expects a list of IDs
  vpc_security_group_ids = [aws_security_group.allow_web_traffic.id]

  # Assuming script.sh exists in the same directory as your Terraform files
  user_data = file("${path.module}/Mainscript.sh")

  tags = {
    Name        = "MyTerraformInstance-1" # Updated name for clarity
    Environment = "Development"
  }
}


# Allocate an Elastic IP (static public IP)
resource "aws_eip" "instance_1_eip" {
  instance = aws_instance.instance_1.id
  vpc      = true

  # Optional: Add a tag to the EIP itself
  tags = {
    Name = "EIP for MyTerraformInstance-1"
  }

  depends_on = [aws_instance.instance_1]
}



# --- Outputs ---

# Output for Instance 1
output "instance_1_id" {
  description = "ID of the first EC2 instance"
  value       = aws_instance.instance_1.id
}

output "instance_1_static_public_ip" {
  description = "Static Public IP address (Elastic IP) of the first EC2 instance"
  value       = aws_eip.instance_1_eip.public_ip
}

output "instance_1_private_ip" {
  description = "Private IP address of the first EC2 instance"
  value       = aws_instance.instance_1.private_ip
}


