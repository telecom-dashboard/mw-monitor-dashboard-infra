# ec2_security_group

Creates the public security group for the single EC2 MVP host.

It allows:
- HTTP
- HTTPS
- optional SSH from explicitly allowed CIDRs

The backend app port and database port stay private on the instance itself.
