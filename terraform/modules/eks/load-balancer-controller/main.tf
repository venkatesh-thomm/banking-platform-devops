resource "aws_iam_policy" "this" {
  name        = "${var.cluster_name}-aws-load-balancer-controller"
  description = "IAM policy for AWS Load Balancer Controller"

  policy = file("${path.module}/iam_policy.json")

  tags = {
    Project     = "banking-platform"
    Environment = var.environment
  }
}

data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Federated"
      identifiers = [var.oidc_provider_arn]
    }

    actions = [
      "sts:AssumeRoleWithWebIdentity"
    ]

    condition {
      test     = "StringEquals"
      variable = "${var.oidc_provider_url}:sub"

      values = [
        "system:serviceaccount:kube-system:aws-load-balancer-controller"
      ]
    }

    condition {
      test     = "StringEquals"
      variable = "${var.oidc_provider_url}:aud"

      values = [
        "sts.amazonaws.com"
      ]
    }
  }
}

resource "aws_iam_role" "this" {
  name               = "${var.cluster_name}-aws-load-balancer-controller"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json

  tags = {
    Project     = "banking-platform"
    Environment = var.environment
  }
}

resource "aws_iam_role_policy_attachment" "this" {
  role       = aws_iam_role.this.name
  policy_arn = aws_iam_policy.this.arn
}

resource "helm_release" "this" {
  name       = "aws-load-balancer-controller"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  namespace  = "kube-system"

  set = [
    {
      name  = "clusterName"
      value = var.cluster_name
    },
    {
      name  = "region"
      value = "us-east-1"
    },
    {
      name  = "vpcId"
      value = var.vpc_id
    },
    {
      name  = "serviceAccount.create"
      value = "true"
    },
    {
      name  = "serviceAccount.name"
      value = "aws-load-balancer-controller"
    },
    {
      name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
      value = aws_iam_role.this.arn
    }
  ]

  depends_on = [
    aws_iam_role_policy_attachment.this
  ]
}
