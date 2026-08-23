#!/bin/bash
# Deploys the EKS stack. Requires VPC_ID, PUBLIC_SUBNET_1/2/3, and
# PRIVATE_SUBNET_1/2/3 to be set in the environment - see README.md.
set -euo pipefail

: "${VPC_ID:?Set VPC_ID to your VPC's ID}"
: "${PUBLIC_SUBNET_1:?Set PUBLIC_SUBNET_1}"
: "${PUBLIC_SUBNET_2:?Set PUBLIC_SUBNET_2}"
: "${PUBLIC_SUBNET_3:?Set PUBLIC_SUBNET_3}"
: "${PRIVATE_SUBNET_1:?Set PRIVATE_SUBNET_1}"
: "${PRIVATE_SUBNET_2:?Set PRIVATE_SUBNET_2}"
: "${PRIVATE_SUBNET_3:?Set PRIVATE_SUBNET_3}"

STACK_NAME="${STACK_NAME:-cluster-eks-demo}"
REGION="${REGION:-us-east-1}"

aws cloudformation create-stack \
  --region "$REGION" \
  --stack-name "$STACK_NAME" \
  --capabilities CAPABILITY_NAMED_IAM \
  --template-body file://eks-fargate-cft.yaml \
  --parameters \
    ParameterKey=VPC,ParameterValue="$VPC_ID" \
    ParameterKey=PublicSubnet1,ParameterValue="$PUBLIC_SUBNET_1" \
    ParameterKey=PublicSubnet2,ParameterValue="$PUBLIC_SUBNET_2" \
    ParameterKey=PublicSubnet3,ParameterValue="$PUBLIC_SUBNET_3" \
    ParameterKey=PrivateSubnet1,ParameterValue="$PRIVATE_SUBNET_1" \
    ParameterKey=PrivateSubnet2,ParameterValue="$PRIVATE_SUBNET_2" \
    ParameterKey=PrivateSubnet3,ParameterValue="$PRIVATE_SUBNET_3" \
    ParameterKey=EKSClusterName,ParameterValue="$STACK_NAME"
