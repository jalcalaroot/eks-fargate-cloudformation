#!/bin/bash
set -euo pipefail

STACK_NAME="${STACK_NAME:-cluster-eks-demo}"
REGION="${REGION:-us-east-1}"

aws cloudformation delete-stack \
  --region "$REGION" \
  --stack-name "$STACK_NAME"
