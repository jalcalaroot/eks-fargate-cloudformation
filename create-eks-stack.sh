aws cloudformation create-stack \
  --region us-east-1 \
  --stack-name cluster-eks-example \
  --capabilities CAPABILITY_NAMED_IAM \
  --template-body file://eks-fargate-cft.yaml
