# ecs-dns-updater

`ecs-dns-updater` provides a container image that can update DNS at ECS
service start up. This provides a very simple service discovery mechanism
for services without a load balancer.

## Prequisites

You must be running a version of ECS agent that provides ECS metadata
(v1.15.0 or later).

The ECS agent must have the following variables set to true

* `ECS_ENABLE_CONTAINER_METADATA`
* `ECS_ENABLE_TASK_IAM_ROLE`

## Building the container

```
docker build -t ecs-dns-updater container
```

## Creating the IAM role

Create an IAM role for use by `ecs-dns-updater` using the
IAM policy defined in iam/ecs-dns-updater-policy.json and the
trust policy defined in iam/ecs-task-trust-policy.json.

The policy is fairly simple, it needs to be able to look up
information about the container, the underlying instance and
the host and zone information from route53.

## Creating a service that updates DNS

The container definitions for a service using ecs-dns-updater would
look a little like:

```
containerDefinitions:
  - name: "application-db"
    image: postgres
    essential: true
    memory: 3096
  - name: "ecs-dns-updater-task"
    essential: false
    image: "111111111111.dkr.ecr.ap-southeast-2.amazonaws.com/ecs-dns-updater:latest"
    memory: 128
    environment:
      - name: DNS_ZONE
        value: "my.private.dns.zone"
      - name: DNS_HOST
        value: "application-db"
```

Using `essential: false` will mean that the task runs at service start up, stops, and
is then never restarted until the service restarts (typically because the agent
underneath has moved)

# Acknowledgments

This work was developed as part of my job at XVT. Thanks to XVT for paying me
to deliver open source work for the benefit of the wider community.
