resource "aws_iam_role" "eks-iam-role" {
  name               = "eks-iam-role"
  path               = "/"
  assume_role_policy = <<EOF
  {
    "Version": "2012-10-17",
    "Statement": [
      {
       "Effect": "Allow",
       "Principal": {
          "Service": "eks.amazonaws.com"
       },
       "Action": "sts:AssumeRole"
      }
    ]
    }
    EOF
}


resource "aws_iam_role_policy_attachment" "AmazonEKSClusterPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks-iam-role.name
}

resource "aws_iam_role_policy_attachment" "AmazonEC2ContainerRegistryReadOnly-EKS" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.eks-iam-role.name
}


resource "aws_eks_cluster" "eks-cluster" {
  name     = "terraform-cluster"
  role_arn = aws_iam_role.eks-iam-role.arn

  vpc_config {
    subnet_ids = [aws_subnet.public["AZ1"].id, aws_subnet.public["AZ2"].id]
  }

  depends_on = [aws_iam_role.eks-iam-role, 
		aws_vpc.terraform-vpc ]
}


resource "aws_iam_role" "workernodes" {
  name = "eks-node-group"

  assume_role_policy = jsonencode({
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
    Version = "2012-10-17"
  })
}


resource "aws_iam_role_policy_attachment" "AmazonEKSWorkerNodePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.workernodes.name

}

resource "aws_iam_role_policy_attachment" "AmazonEKS_CNI_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.workernodes.name

}

resource "aws_iam_role_policy_attachment" "EC2InstanceProfileForImageBuilderECRContainerBuilds" {
  policy_arn = "arn:aws:iam::aws:policy/EC2InstanceProfileForImageBuilderECRContainerBuilds"
  role       = aws_iam_role.workernodes.name

}

resource "aws_iam_role_policy_attachment" "AmazonEC2ContainerRegistryReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.workernodes.name

}


resource "aws_eks_node_group" "worker-node-group" {
  cluster_name    = "terraform-cluster"
  node_group_name = "terraform-nodesgroup"
  node_role_arn   = aws_iam_role.workernodes.arn
  subnet_ids      = [aws_subnet.private["AZ1"].id, aws_subnet.private["AZ2"].id]
  instance_types  = ["t2.micro"]

  scaling_config {
    desired_size = 2
    max_size     = 2
    min_size     = 1
  }

  update_config {
    max_unavailable = 1
  }

  depends_on = [
    aws_eks_cluster.eks-cluster,
    aws_internet_gateway.terraform-igw,
    aws_iam_role_policy_attachment.AmazonEC2ContainerRegistryReadOnly,
    aws_subnet.private,
    aws_subnet.public
  ]

  tags = {
    Name = "terra_eks_node_group"
  }
}
