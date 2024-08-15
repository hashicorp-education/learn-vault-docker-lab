# Vault Docker Lab

Vault Docker Lab (VDL) is a minimal 5-node [Vault](https://www.vaultproject.io) cluster running the official [Vault container image](https://hub.docker.com/_/vault/) with [Integrated Storage](https://developer.hashicorp.com/vault/docs/configuration/storage/raft) on [Docker](https://www.docker.com/products/docker-desktop/). VDL uses a `Makefile`, [Terraform CLI](https://developer.hashicorp.com/terraform/cli), and the [Terraform Docker Provider](https://registry.terraform.io/providers/kreuzwerker/docker/latest/docs) to build the cluster.

## Why?

You can use VDL to build a small containerized cluster with [Integrated Storage](https://developer.hashicorp.com/vault/docs/configuration/storage/raft) for development, education, or testing. **You should not use VDL for production use cases**.

## How?

You can run your own VDL with Docker, Terraform, and the Terraform Docker provider.

## Prerequisites

Your host computer must have the following software installed to run VDL:

### Required

- [Docker](https://www.docker.com/products/docker-desktop/) (tested with Docker Desktop version 4.32.0 on macOS version 14.5)

- [Terraform CLI](https://developer.hashicorp.com/terraform/downloads) binary installed in your system PATH (tested with version 1.9.3 darwin_arm64 on macOS version 14.5)

### Optional

- [Vault CLI](https://developer.hashicorp.com/vault/install) binary installed in your system PATH if you want to use CLI commands

> **NOTE:** VDL functions on Linux (last tested on Ubuntu 22.04) and macOS with Intel or Apple silicon processors (last tested on macOS 14.5).

## Run your own VDL

Follow these steps to run your own VDL.

1. Clone this repository.

   ```shell
   git clone https://github.com/hashicorp-education/learn-vault-docker-lab.git
   ```

1. Change into the lab directory.

   ```shell
   cd learn-vault-docker-lab
   ```

1. Add the VDL Certificate Authority certificate to your operating system trust store.

   - For macOS:

     ```shell
     sudo security add-trusted-cert -d -r trustAsRoot \
        -k /Library/Keychains/System.keychain \
        ./containers/vdl_node_1/certs/vault_docker_lab_ca.pem
     ```

     > **NOTE**: The OS prompts for your user password, and sometimes prompts twice; enter your user password as needed to add the certificate.

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

        From within this repository directory, copy the VDL CA certificate to the `/usr/local/share/ca-certificates` directory.

        ```shell
        sudo cp ./containers/vdl_node_1/certs/vault_docker_lab_ca.pem \
            /usr/local/share/ca-certificates/vault_docker_lab_ca.crt
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

       Copy the VDL CA certificate to `/usr/local/share/ca-certificates`.

       ```shell
       sudo cp containers/vdl_node_1/certs/vault_docker_lab_ca.pem \
           /usr/local/share/ca-certificates/vault_docker_lab_ca.crt
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

       From within this repository directory, copy the VDL CA certificate to the `/etc/pki/ca-trust/source/anchors` directory.

        ```shell
        sudo cp ./containers/vdl_node_1/certs/vault_docker_lab_ca.pem \
            /etc/pki/ca-trust/source/anchors/vault_docker_lab_ca.crt
        # No output expected
        ```

        Update CA trust.

        ```shell
        sudo update-ca-trust
        # No output expected
        ```

       From within this repository directory, copy the VDL CA certificate to the `/usr/local/share/ca-certificates` directory.

        ```shell
        sudo cp ./containers/vdl_node_1/certs/vault_docker_lab_ca.pem \
            /usr/local/share/ca-certificates/vault_docker_lab_ca.crt
        # No output expected
        ```

        Update certificates.

        ```shell
        sudo update-ca-certificates
        # No output expected
        ```

1. Type `make` and press `[return]`; output resembles this example, and includes the initial root token value for the sake of convenience and ease of use.

   ```plaintext
   VDL initializing Terraform workspace ...done.
   VDL applying Terraform configuration ...done.
   VDL check Vault active node status ...done.
   VDL check Vault initialization status ...done.
   VDL unsealing cluster nodes .....node 2. node 3. node 4. node 5. done.
   VDL enable audit device ...done.
   VDL export VAULT_ADDR for the active node: export VAULT_ADDR=https://127.0.0.1:8200
   VDL login to Vault with initial root token: vault login hvs.euAmS2Wc0ff3339uxTKYVtqK
   ```

1. Follow the instructions to set an appropriate `VAULT_ADDR` environment variable, and login to Vault with the initial root token value if you are using CLI. You can use the initial root token value for API requests or to login to the [web UI](https://127.0.0.1:8200).

## Notes

The following notes describe the VDL container structure, and give tips on commonly used features.

### Configuration, data & logs

The configuration, data, and audit device log files live in a subdirectory  named after the server under `containers`. For example, here is the structure of the first server, _vdl_node_1_ as it appears when active.

```shell
tree containers/vdl_node_1
```

Example output:

```plaintext
containers/vdl_node_1
├── certs
│   ├── server_cert.pem
│   ├── server_key.pem
│   ├── vault_docker_lab_ca.pem
│   └── vault_docker_lab_ca_chain.pem
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

> **Note**: If you need access to the unseal key, you can find it along with the initial root token value in the `.vdl_node_1_init` file.

### Run a certain Vault version

VDL offers the latest available Vault Docker image version, but you can also run a specific version of Vault for which an image exists with the `TF_VAR_vault_version` environment variable like this:

```shell
TF_VAR_vault_version=1.11.0 make
```

> **Tip**: You should use Vault versions >= 1.11.0 for ideal Integrated Storage support.

### Run Vault Enterprise

VDL runs the Vault community edition by default, but you can also run the Enterprise edition.

> **NOTE**: You must have an [Enterprise license](https://www.hashicorp.com/products/vault/pricing) to run the Vault Enterprise image.

Export the `TF_VAR_vault_license` environment variable with your Vault Enterprise license string as the value. For example:

```shell
export TF_VAR_vault_license=02E2VCBORGUIRSVJVCECNSNI...
```

Export the `TF_VAR_vault_edition` environment variable to specify `vault-enterprise` as the value.

```shell
export TF_VAR_vault_edition=vault-enterprise
```

Make VDL.

```shell
make
```

### Set the Vault server log level

The default Vault server log level is Info, but you can specify another log level like `Debug`, with the `TF_VAR_vault_log_level` environment variable like this:

```shell
TF_VAR_vault_log_level=Debug make
```

### Stage a cluster

By default, VDL automatically initializes and unseals Vault. If you'd rather perform these steps yourself, you can specify that they're skipped.

Stage a cluster.

```shell
make stage
```

Example output:

```plaintext
[VDL] Initializing Terraform workspace ...Done.
[VDL] Applying Terraform configuration ...Done.
[VDL] Export VAULT_ADDR for the active node: export VAULT_ADDR=https://127.0.0.1:8200
[VDL] Vault is not initialized or unsealed. You must initialize and unseal Vault prior to use.
```

### Benchmark example

You can use [vault-benchmark]() with the example configuration included in `benchmark-example/config/vault-benchmark-config.hcl` and this command line example (make sure you login with the initial root token first).

```shell
docker run \
    --volume="$PWD"/benchmark-example:/config \
    --ip 10.1.42.74 \
    --name learn-vault-benchmark \
    --network vault_docker_lab_network \
    --env "VAULT_TOKEN=$(cat ~/.vault-token)" \
    --env 'VAULT_ADDR=https://10.1.42.101:8200' \
    --env 'VAULT_SKIP_VERIFY=true' \
    --rm \
    hashicorp/vault-benchmark vault-benchmark run -config=/config/vault-benchmark-config.hcl
```

### Docker resource usage

The screenshot shows a VDL that has been up but idle for 25 minutes.

<img width="732" alt="2023-09-01_14-04-54" src="https://github.com/hashicorp-education/learn-vault-docker-lab/assets/77563/5ff76eed-7c70-4bdd-bca2-3a478d878b10">

### Cleanup

To clean up Docker containers and all generated artifacts, **including audit device log files**:

```shell
make clean
```

Example output:

```plaintext
[VDL] Destroying Terraform configuration ...Done.
[VDL] Removing artifacts created by VDL ...Done.
```

To clean up **everything** including Terraform runtime configuration and state:

```shell
make cleanest
```

Example output:

```plaintext
[VDL] Destroying Terraform configuration ...Done.
[VDL] Removing artifacts created by VDL ...Done.
[VDL] Removing all Terraform runtime configuration and state ...Done.
```

To remove the CA certificate from your OS trust store:

- For macOS:

  ```shell
  sudo security delete-certificate -c "vault-docker-lab Intermediate Authority"
  # no output expected
  ```

  - The OS prompts you for your user password; enter it to add the certificate.

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

The tutorial library also has a wide range of intermediate and advanced tutorials with integrated labs.

The [API documentation](https://developer.hashicorp.com/vault/api-docs) and [product documentation](https://developer.hashicorp.com/vault/docs) are also great learning resources.
