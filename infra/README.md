# Infrastructure Deployment Overview

**Note**: All infrastructure deployments take some input variables to appropriately configure your infrastructure.

Some variables provide default values, e.g., `auth` as the subdomain to attach to your authentication service, while others are more bespoke. Please see the corresponding `README.md` file for the infrastructure component to see which variables provide default values and which do not.

Each folder contains a file named `example-variables.tfvars` with variables that cannot provide default values for one reason or another (access keys, network configuration, etc.).

There is also a [shared-example-variables.tfvars](./shared-example-variables.tfvars) in the `/infra` root that contains variables that are re-used across _all_ infrastructure deployments. This is especially helpful for some of the complex object filters used to identify a VPC and corresponding subnets

## Infrastructure Components

Infrastructure deployments should be completed in the following sequence since latter steps rely on one or more of their predecessors.

1. [Authentication Service](./auth/README.md) (if using)
1. [Gateway Service](./gateway/README.md)
1. [Applications](./applications/README.md)

