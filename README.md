# Vault Docker Lab

## What?

Vault Docker Lab is a minimal 5-node [Vault](https://www.vaultproject.io) cluster running the official [Vault Docker image](https://hub.docker.com/_/vault/) with [Integrated Storage](https://developer.hashicorp.com/vault/docs/configuration/storage/raft) on [Docker](https://www.docker.com/products/docker-desktop/). A `Makefile`, [Terraform CLI](https://developer.hashicorp.com/terraform/cli), and the [Terraform Docker Provider](https://registry.terraform.io/providers/kreuzwerker/docker/latest/docs) power the cluster deployment.

## Why?

To establish a small local Vault cluster with [Integrated Storage](https://developer.hashicorp.com/vault/docs/configuration/storage/raft) for development, education, and testing, but **certainly not for production**.

## How?

You can make your own Vault Docker Lab with this repository.

## Prerequisites

To make a Vault Docker Lab, your host computer must have the following software installed:

- [Docker](https://www.docker.com/products/docker-desktop/) (tested with Docker Desktop version 4.22.1 on macOS version 13.5.1)

- [Terraform CLI](https://developer.hashicorp.com/terraform/downloads) binary installed in your system PATH (tested with version 1.5.6 darwin_arm64 on macOS version 13.5.1)

> **NOTE:** Vault Docker Lab functions on Linux (last tested on Ubuntu 22.04) and macOS (last tested on 15.3.2) with Intel or Apple silicon processors.

## Make your own Vault Docker Lab

There are just a handful of steps to make your own Vault Docker Lab.

1. Clone this repository.

   ```shell
   git clone https://github.com/hashicorp-education/learn-vault-docker-lab.git
   ```

1. Change into the lab directory.

   ```shell
   cd learn-vault-docker-lab
   ```

1. Add the Vault Docker Lab Certificate Authority certificate to your operating system trust store.

   - For macOS:

     ```shell
     sudo security add-trusted-cert -d -r trustAsRoot \
        -k /Library/Keychains/System.keychain \
        ./containers/vault_docker_lab_1/certs/vault-docker-lab-ca.pem
     ```

     > **NOTE**: The `sudo` utility prompts for your user password, and sometimes can prompt twice; enter your user password as needed to add the certificate to the macOS keychain.

   - For Linux:

     - **Alpine**

        Update the package cache and install the `ca-certificates` package.

        ```shell
        sudo apk update && sudo apk add ca-certificates
        fetch https://dl-cdn.alpinelinux.org/alpine/v3.14/main/aarch64/APKINDEX.tar.gz
        fetch https://dl-cdn.alpinelinux.org/alpine/v3.14/community/aarch64/APKINDEX.tar.gz
        v3.14.8-86-g0df2022316 [https://dl-cdn.alpinelinux.org/alpine/v3.14/main]
        v3.14.8-86-g0df2022316 [https://dl-cdn.alpinelinux.org/alpine/v3.14/community]
        OK: 14832 distinct packages available
        OK: 9 MiB in 19 packages
        ```

        From within this repository directory, copy the Vault Docker Lab CA certificate to the `/usr/local/share/ca-certificates` directory.

        ```shell
        sudo cp ./containers/vault_docker_lab_1/certs/vault-docker-lab-ca.pem \
            /usr/local/share/ca-certificates/vault-docker-lab-ca.crt
        # No output expected
        ```

        Append the certificates to the file `/etc/ssl/certs/ca-certificates.crt`.

        ```shell
        sudo sh -c "cat /usr/local/share/ca-certificates/vault_docker_lab_ca.crt >> /etc/ssl/certs/ca-certificates.crt"
        # No output expected
        ```

        Update certificates.

        ```shell
        sudo sudo update-ca-certificates
        # No output expected
        ```

     - **Debian & Ubuntu**

        Install the `ca-certificates` package.

        ```shell
        sudo apt-get install -y ca-certificates
         Reading package lists... Done
         ...snip...
         Updating certificates in /etc/ssl/certs...
         0 added, 0 removed; done.
         Running hooks in /etc/ca-certificates/update.d...
         done.
        ```

       Copy the Vault Docker Lab CA certificate to `/usr/local/share/ca-certificates`.

       ```shell
       sudo cp containers/vault_docker_lab_1/certs/vault-docker-lab-ca.pem \
           /usr/local/share/ca-certificates/vault-docker-lab-ca.crt
       # No output expected
       ```

       Update certificates.

       ```shell
       sudo update-ca-certificates
       Updating certificates in /etc/ssl/certs...
       1 added, 0 removed; done.
       Running hooks in /etc/ca-certificates/update.d...
       done.
       ```

     - **RHEL**

       From within this repository directory, copy the Vault Docker Lab CA certificate to the `/etc/pki/ca-trust/source/anchors` directory.

        ```shell
        sudo cp ./containers/vault_docker_lab_1/certs/vault-docker-lab-ca.pem \
            /etc/pki/ca-trust/source/anchors/vault-docker-lab-ca.crt
        # No output expected
        ```

        Update CA trust.

        ```shell
        sudo update-ca-trust
        # No output expected
        ```

       From within this repository directory, copy the Vault Docker Lab CA certificate to the `/usr/local/share/ca-certificates` directory.

        ```shell
        sudo cp ./containers/vault_docker_lab_1/certs/vault-docker-lab-ca.pem \
            /usr/local/share/ca-certificates/vault-docker-lab-ca.crt
        # No output expected
        ```

        Update certificates.

        ```shell
        sudo update-ca-certificates
        # No output expected
        ```

1. Type `make` and press `[return]`; successful output resembles this example, and includes the initial root token value (for the sake of convenience and ease of use).

   ```plaintext
   [vault-docker-lab] Initializing Terraform workspace ...Done.
   [vault-docker-lab] Applying Terraform configuration ...Done.
   [vault-docker-lab] Checking Vault active node status ...Done.
   [vault-docker-lab] Checking Vault initialization status ...Done.
   [vault-docker-lab] Unsealing cluster nodes .....node 2. node 3. node 4. node 5. Done.
   [vault-docker-lab] Enable audit device ...Done.
   [vault-docker-lab] Export VAULT_ADDR for the active node: export VAULT_ADDR=https://localhost:8200
   [vault-docker-lab] Login to Vault with initial root token: vault login hvs.6Eq3tM7Lc0ff33cq7r9WRFFD
   ```

1. Follow the instructions to set an appropriate `VAULT_ADDR` environment variable, and login to Vault with the initial root token value.

## Notes

The following notes should help you better understand the container structure Vault Docker Lab uses, along with tips on commonly used features.

### Configuration, data & logs

The configuration, data, TLS material, and audit device log files live in a subdirectory under `containers` for each server. For example, here is the structure of the first server, _vault_docker_lab_1_ as it appears when active.

```shell
$ tree containers/vault_docker_lab_1
containers/vault_docker_lab_1
├── certs
│   ├── server-cert.pem
│   ├── server-key.pem
│   ├── vault-docker-lab-ca.pem
│   └── vault_docker-lab-ca-chain.pem
├── config
│   └── server.hcl
├── data
│   ├── raft
│   │   ├── raft.db
│   │   └── snapshots
│   └── vault.db
└── logs

7 directories, 7 files
```

### Enable the monitoring stack

Vault Docker lab ships with Prometheus to get telemetry metrics from the cluster leader node, and Grafana to use Prometheus as a data source with a default dashboard for visualization.

You can enable the complete monitoring stack by starting Vault Docker Lab with this command:

```shell
make with-monitoring
```

This enables both Prometheus and Grafana, with everything configured for you.

You can access Grafana at [http://localhost:3001](http://localhost:3001) with these credentials:

- Username: `admin`
- Password: `2LearnVault`

If you need to separately enable Prometheus, you can use:

```shell
make prometheus
```

Likewise, you can separately enable Grafana with:

```shell
make grafana
```

The monitoring stack is automatically cleaned up when you use `make clean`.

### Run a specific Vault version

Vault Docker Lab tries to keep current and offer the latest available Vault Docker image version. You can run a specific version of Vault for which an image exists with the `TF_VAR_vault_version` environment variable like this: 

```shell
TF_VAR_vault_version=1.11.0 make
```

> **Tip**: Vault versions >= 1.11.0 are ideal for Integrated Storage support.

### Run Vault Enterprise

Vault Docker Lab runs the Vault community edition by default, but you can also run the Enterprise edition.

> **NOTE**: You must have an [Enterprise license](https://www.hashicorp.com/products/vault/pricing) to run the Vault Enterprise image.

Export the `TF_VAR_vault_license` environment variable with your Vault Enterprise license string as the value. For example:

```shell
export TF_VAR_vault_license=02E2VCBORGUIRSVJVCECNSNI...
```

Export the `TF_VAR_vault_edition` environment variable to specify `vault-enterprise` as the value.

```shell
export TF_VAR_vault_edition=vault-enterprise
```

Make Vault Docker Lab.

```shell
make
```

### Set the Vault server log level

The default Vault server log level is Info, but you can specify another log level like `Debug`, with the `TF_VAR_vault_log_level` environment variable like this:

```shell
TF_VAR_vault_log_level=Debug make
```

### Stage a cluster

By default, vault-docker-lab automatically initializes and unseals Vault. If you'd rather perform these steps yourself, you can specify that they're skipped.

Stage a cluster.

```shell
make stage
```

Example output:

```plaintext
[vault-docker-lab] Initializing Terraform workspace ...Done.
[vault-docker-lab] Applying Terraform configuration ...Done.
[vault-docker-lab] Export VAULT_ADDR for the active node: export VAULT_ADDR=https://127.0.0.1:8200
[vault-docker-lab] Vault is not initialized or unsealed. You must initialize and unseal Vault prior to use.
```

### Docker resource usage

The screenshot shows a Vault Docker Lab that has been up but idle for 25 minutes.

<img width="732" alt="2023-09-01_14-04-54" src="https://github.com/hashicorp-education/learn-vault-docker-lab/assets/77563/5ff76eed-7c70-4bdd-bca2-3a478d878b10">

### Cleanup

To clean up Docker containers and all generated artifacts, **including audit device log files**:

```shell
make clean
```

Example output:

```plaintext
[vault-docker-lab] Destroying Terraform configuration ...Done.
[vault-docker-lab] Removing artifacts created by Vault Docker Lab ...Done.
```

To clean up **everything** including Terraform runtime configuration and state:

```shell
make cleanest
```

Example output:

```plaintext
[vault-docker-lab] Destroying Terraform configuration ...Done.
[vault-docker-lab] Removing artifacts created by Vault Docker Lab ...Done.
[vault-docker-lab] Removing all Terraform runtime configuration and state ...Done.
```

To remove the CA certificate from your OS trust store:

- For macOS:

  ```shell
  sudo security delete-certificate -c "vault-docker-lab Intermediate Authority"
  # no output expected
  ```

  - The `sudo` utility prompts for your user password; enter your user password to add the certificate.

- For Linux:

  - Follow the documentation for your specific Linux distribution to remove the certificate.

Unset related environment variables.

```shell
unset TF_VAR_vault_edition F_VAR_vault_license TF_VAR_vault_version VAULT_ADDR
```

## Help and reference

A great resource for learning more about Vault is the [HashiCorp Developer](https://developer.hashicorp.com) site, which has a nice [Vault tutorial library](https://developer.hashicorp.com/tutorials/library?product=vault) available.

If you are new to Vault, check out the **Get Started** tutorial series:

- [CLI Quick Start](https://developer.hashicorp.com/vault/tutorials/getting-started)
- [HCP Vault Quick Start](https://developer.hashicorp.com/vault/tutorials/cloud)
- [UI Quick Start](https://developer.hashicorp.com/vault/tutorials/getting-started-ui)

The tutorial library also has a wide range of intermediate and advanced tutorials with integrated learning labs.

The [API documentation](https://developer.hashicorp.com/vault/api-docs) and [product documentation](https://developer.hashicorp.com/vault/docs) are also great learning resources.
