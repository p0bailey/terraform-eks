#
# VPC Resources
#  * VPC
#  * Subnets
#  * Internet Gateway
#  * Route Table
#

resource "aws_vpc" "demo" {
  cidr_block = "${var.cidr_block}"

  tags = "${
      map(
       "Name", "terraform-eks-demo-node",
       "kubernetes.io/cluster/${var.cluster-name}", "shared",
      )
    }"
}

resource "aws_subnet" "demo" {
  count                   = "${var.az_count}"
  cidr_block              = "${cidrsubnet(aws_vpc.demo.cidr_block, 8, count.index)}"
  availability_zone       = "${data.aws_availability_zones.available.names[count.index]}"
  vpc_id                  = "${aws_vpc.demo.id}"
  map_public_ip_on_launch = true

  tags = "${
      map(
       "Name", "terraform-eks-demo-node",
       "kubernetes.io/cluster/${var.cluster-name}", "shared",
      )
    }"
}

resource "aws_internet_gateway" "demo" {
  vpc_id = "${aws_vpc.demo.id}"

  tags {
    Name = "terraform-eks-demo"
  }
}

resource "aws_route_table" "demo" {
  vpc_id = "${aws_vpc.demo.id}"
  count  = "${var.az_count}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.demo.id}"
  }
}

resource "aws_route_table_association" "public_route_table_association" {
  count          = "${var.az_count}"
  subnet_id      = "${element(aws_subnet.demo.*.id, count.index)}"
  route_table_id = "${element(aws_route_table.demo.*.id, count.index)}"
}
