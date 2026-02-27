# DevOps Engineer Task

This repository contains an automated environment bootstrap aimed at fulfilling the recruitment task requirements. It provisions a single-node k3s cluster, deploys ArgoCD, and sets up continuous syncing of a sample web application.

## Repository Layout

* `ansible/`: Ansible playbook (`site.yml`), config, inventory, and templates.
* `kubernetes/app/`: Kubernetes manifests (Deployment, Service, Namespace) for an Nginx web application.
* `argocd/`: Example Application manifest (synchronizes `kubernetes/app` directory).
* `Makefile`: Main entrypoint for launching configuration and checking status.

## Prerequisites

This must run on a **Linux host** (k3s requires a Linux kernel - macOS is not supported). You need:
* A modern Linux distribution with systemd
* Ansible: `pip3 install ansible`
* curl and git

## Deployment

Clone this repository, navigate into it, and run:

```bash
make bootstrap
```

The `REPO_URL` and branch are detected automatically from your local git remote. The only prerequisite is that the repository is public and has an `origin` remote configured, which is the default state after a normal `git clone`.

Ansible will ask for your sudo password once to install k3s and apply kernel config.

The playbook automates the following steps:
1. Applies required sysctl network optimizations.
2. Installs a standalone k3s cluster.
3. Creates the required namespace and deploys ArgoCD from stable upstream manifests.
4. Generates and applies the ArgoCD Application that points back to this repository to track Kubernetes manifests.

## Verification

Once the playbook execution finishes, you can use the provided target to verify the cluster health, the ArgoCD pod state, and the availability of the web application:

```bash
make check
```

This checks cluster node readiness, reads the ArgoCD Application sync and health status directly from the API, lists pod and service state in the web namespace, and issues a live curl against the NodePort endpoint. All four checks must pass for the deployment to be considered complete.

To access the ArgoCD web interface, expose the service locally:

```bash
k3s kubectl -n argocd port-forward svc/argocd-server 8080:443
```

Navigate to `https://localhost:8080` in your web browser. The standard login name is `admin`. To retrieve the dynamically generated password, run:

```bash
make argocd-password
```

To access the deployed Nginx application locally:

```bash
k3s kubectl -n web port-forward svc/web-nginx 8081:80
```

Then open your browser to `http://localhost:8081`.

*(Alternatively, if accessing directly from the Linux host or its network, it is exposed on NodePort `30080`, e.g. `http://localhost:30080`)*
