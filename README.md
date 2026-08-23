# eks-fargate-cloudformation

CloudFormation template for an AWS EKS cluster with a **managed EC2 node
group**, deployed into an existing VPC with public and private subnets
across 3 AZs.

> **Naming note:** despite the repo name, this template does not use EKS
> Fargate profiles - it provisions a standard `AWS::EKS::Nodegroup` backed
> by EC2 instances. Kept the name for now; if you're looking for serverless
> Fargate pods, that would mean adding an `AWS::EKS::FargateProfile`
> resource on top of this.

## Architecture

```
Existing VPC (3 public + 3 private subnets, 3 AZs)
   |
   +-- EKS Control Plane (public + private endpoint access)
   |     - logs API + audit to CloudWatch
   |
   +-- Managed EC2 Node Group (in the 3 private subnets)
   |     - AL2_x86_64, On-Demand, scaling min=desired=max=NumWorkerNodes
   |
   +-- Add-ons: vpc-cni, kube-proxy, coredns, aws-ebs-csi-driver,
         aws-guardduty-agent, amazon-cloudwatch-observability
```

Control-plane <-> node communication is locked down to HTTPS (443) and
kubelet (10250) between two dedicated security groups.

## Prerequisites

- An existing VPC with 3 public + 3 private subnets across 3 AZs (this
  template does not create networking - bring your own).
- AWS CLI configured, IAM permissions to create the cluster, node group,
  IAM roles (`CAPABILITY_NAMED_IAM`), and security groups.
- `kubectl` (to use the cluster after it's created).

## Deploy

Set your VPC/subnet IDs as environment variables, then run the script:

```bash
export VPC_ID=vpc-xxxxxxxx
export PUBLIC_SUBNET_1=subnet-xxxxxxxx
export PUBLIC_SUBNET_2=subnet-xxxxxxxx
export PUBLIC_SUBNET_3=subnet-xxxxxxxx
export PRIVATE_SUBNET_1=subnet-xxxxxxxx
export PRIVATE_SUBNET_2=subnet-xxxxxxxx
export PRIVATE_SUBNET_3=subnet-xxxxxxxx

./create-eks-stack.sh
```

`STACK_NAME` (default `cluster-eks-demo`) and `REGION` (default
`us-east-1`) can also be overridden as environment variables.

Once `CREATE_COMPLETE`, get `kubectl` access:

```bash
aws eks update-kubeconfig --name cluster-eks-demo --region us-east-1
kubectl get nodes
```

## Destroy

```bash
./delete-eks-stack.sh
```

The node group is deleted before the control plane; this can take
several minutes.

## Parameters

| Parameter | Type | Notes |
|---|---|---|
| `VPC` | `AWS::EC2::VPC::Id` | Required, no default |
| `PublicSubnet1/2/3` | `AWS::EC2::Subnet::Id` | Required, no default |
| `PrivateSubnet1/2/3` | `AWS::EC2::Subnet::Id` | Required, no default - node group runs here |
| `EKSClusterName` | String | Default `cluster-eks-demo` |
| `NumWorkerNodes` | Number | Default `3` (fixed min=desired=max) |
| `EKSVersion` | String | Default `1.30` |
| `DiskSize` | String | Default `100` (GiB, per node) |

## Cost notes

EKS control plane is billed hourly regardless of usage
(~$0.10/hr as of writing), plus EC2 costs for `NumWorkerNodes` nodes at
whatever instance type your node group's launch template ends up using,
plus EBS volumes (`DiskSize` GiB each). Delete the stack when not
actively using it.

## Security notes

- Both public and private API endpoint access are enabled
  (`EndpointPublicAccess`/`EndpointPrivateAccess: true`) - fine for a demo,
  consider disabling public access for anything beyond that.
- Worker node IAM role uses broad AWS-managed policies
  (`AmazonEKSWorkerNodePolicy`, ECR power-user, SSM, CNI, CloudWatch) -
  standard for a getting-started template, but worth tightening with
  scoped policies for production use.
- Add-on versions are pinned to what was current at the time this template
  was written - check for newer versions before deploying against a
  current EKS release.
