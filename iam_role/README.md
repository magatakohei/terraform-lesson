# Usage
```hcl
module "example_sg" {
  source = "./security_group"
  name   = "${var.environment}-example-sg"
  vpc_id = aws_vpc.example.id
  ingress_ports = [
    { port = "80", cidr_blocks = ["0.0.0.0/0"] },
    { port = "443", cidr_blocks = ["0.0.0.0/0", "10.0.65.0/24"] }
  ]
}
```
