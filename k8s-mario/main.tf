provider "aws" {
  region = "ap-south-1"
}

resource "aws_iam_role" "example" {
  name = "eks-node-group-cloud"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "eks.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "example-AmazonEKSClusterPolicy" {
  role = aws_iam_role.example.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

data "aws_vpc" "vpc" {
  default = true
}

data "aws_subnets" "public" {
  filter {
    name = "vpc-id"
    values = [data.aws_vpc.vpc.id]
  }
}
resource "aws_eks_cluster" "cluster" {
  name = "Demo-EKS"
  role_arn = aws_iam_role.example.arn
  vpc_config { 
     subnet_ids = data.aws_subnets.public.ids
  }
  depends_on = [ aws_iam_role_policy_attachment.example-AmazonEKSClusterPolicy,
   ]
}

resource "aws_iam_role" "example1" {
  name = "eks-nodegroup"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "example1-AmazonEKSWorkerNodePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role = aws_iam_role.example1.name
}

resource "aws_iam_role_policy_attachment" "example1-AmazonEKS_CNI_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role = aws_iam_role.example1.name
}

resource "aws_iam_role_policy_attachment" "example1-AmazonEC2ContainerRegistryReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role = aws_iam_role.example1.name
}

resource "aws_eks_node_group" "nodegroup" {
    cluster_name = aws_eks_cluster.cluster.name
    node_group_name = "eks-nodegroup"
    node_role_arn = aws_iam_role.example1.arn
    subnet_ids = data.aws_subnets.public.ids

    scaling_config {
      min_size = 1
      max_size = 2
      desired_size = 1
    }

    instance_types = ["t2.medium"]

    depends_on = [ 
    aws_iam_role_policy_attachment.example1-AmazonEKS_CNI_Policy,
    aws_iam_role_policy_attachment.example1-AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.example1-AmazonEC2ContainerRegistryReadOnly, ]
}