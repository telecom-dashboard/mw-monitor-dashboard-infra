# ec2_host

Creates the single public EC2 host for the MVP stack.

Included:
- one EC2 instance
- one Elastic IP
- one IAM role and instance profile
- SSM access
- CloudWatch Agent policy attachment
- scoped access to the MVP assets bucket
- optional scoped read access to SSM Parameter Store paths

The module stays intentionally simple so the environment root can later be replaced by ALB + ECS without fighting hidden abstractions.
