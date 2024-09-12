# Vault Docker lab

Vault Docker lab is a minimal 5-node [Vault](https://www.vaultproject.io) cluster running the official [Vault container image](https://hub.docker.com/_/vault/) with [Integrated Storage](https://developer.hashicorp.com/vault/docs/configuration/storage/raft) on [Docker](https://www.docker.com/products/docker-desktop/). Vault Docker lab uses a `Makefile`, [Terraform CLI](https://developer.hashicorp.com/terraform/cli), and the [Terraform Docker Provider](https://registry.terraform.io/providers/kreuzwerker/docker/latest/docs) to build the cluster.

## Why?

You can use Vault Docker lab to build a small containerized cluster with [Integrated Storage](https://developer.hashicorp.com/vault/docs/configuration/storage/raft) for development, education, or testing. **You should not use Vault Docker lab for production use cases**.

Vault Docker lab also includes a telemetry stack consisting of Prometheus and Grafana containers. Run the project, access Grafana, paste in the official dashboard, and go.

**One more thing**: want to get your dashboard popping? A benchmark container is also included.

Check the corresponding sections here for more details.

## How?

You can run your own Vault Docker lab with Docker, Terraform, and the Terraform Docker provider.

## Prerequisites

Your host computer must have the following software installed to run Vault Docker lab:

### Required

- [Docker](https://www.docker.com/products/docker-desktop/) (tested with Docker Desktop version 4.32.0 on macOS version 14.5)

- [Terraform CLI](https://developer.hashicorp.com/terraform/downloads) binary installed in your system PATH (tested with version 1.9.3 darwin_arm64 on macOS version 14.5)

### Optional

- [Vault CLI](https://developer.hashicorp.com/vault/install) binary installed in your system PATH if you want to use CLI commands

> **NOTE:** Vault Docker lab functions on Linux (last tested on Ubuntu 22.04) and macOS with Intel or Apple silicon processors (last tested on macOS 14.5).

## Run your own Vault Docker lab

Follow these steps to run your own Vault Docker lab.

1. Clone this repository.

   ```shell
   git clone https://github.com/hashicorp-education/learn-vault-docker-lab.git
   ```

1. Change into the lab directory.

   ```shell
   cd learn-vault-docker-lab
   ```

1. Add the Vault Docker lab Certificate Authority certificate to your operating system trust store.

   - For macOS:

     ```shell
     sudo security add-trusted-cert -d -r trustAsRoot \
        -k /Library/Keychains/System.keychain \
        ./containers/Vault Docker lab_node_1/certs/vault_docker_lab_ca.pem
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

        From within this repository directory, copy the Vault Docker lab CA certificate to the `/usr/local/share/ca-certificates` directory.

        ```shell
        sudo cp ./containers/Vault Docker lab_node_1/certs/vault_docker_lab_ca.pem \
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

       Copy the Vault Docker lab CA certificate to `/usr/local/share/ca-certificates`.

       ```shell
       sudo cp containers/Vault Docker lab_node_1/certs/vault_docker_lab_ca.pem \
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

       From within this repository directory, copy the Vault Docker lab CA certificate to the `/etc/pki/ca-trust/source/anchors` directory.

        ```shell
        sudo cp ./containers/Vault Docker lab_node_1/certs/vault_docker_lab_ca.pem \
            /etc/pki/ca-trust/source/anchors/vault_docker_lab_ca.crt
        # No output expected
        ```

        Update CA trust.

        ```shell
        sudo update-ca-trust
        # No output expected
        ```

       From within this repository directory, copy the Vault Docker lab CA certificate to the `/usr/local/share/ca-certificates` directory.

        ```shell
        sudo cp ./containers/Vault Docker lab_node_1/certs/vault_docker_lab_ca.pem \
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
   👋 Hello from Vault Docker Lab
   [+] Initializing Terraform workspace ...done.
   [+] Applying Terraform configuration ...done.
   [+] Check Vault active node status ...ok.
   [+] Check Vault initialization status ...ok.
   [+] Unsealing cluster nodes .....node 2. node 3. node 4. node 5. done.
   [+] Enable audit device on Vault Docker lab_node_1 in /vault/logs/vault_audit.log done.
   
   [i] Export VAULT_ADDR for the active node: export VAULT_ADDR=https://127.0.0.1:8200
   [i] Login to Vault with initial root token: vault login hvs.rCKq3...c0ff33...HUxxvo7
   ```

1. Follow the instructions to set an appropriate `VAULT_ADDR` environment variable, and login to Vault with the initial root token value if you are using CLI. You can use the initial root token value for API requests or to login to the [web UI](https://127.0.0.1:8200).

### Explore configuration, data & logs

The configuration, data, and audit device log files live in a subdirectory  named after the server under `containers`. For example, here is the structure of the first server, _Vault Docker lab_node_1_ as it appears when active.

```shell
tree containers/Vault Docker lab_node_1
```

Example output:

```plaintext
containers/Vault Docker lab_node_1
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

> **Note**: If you need access to the unseal key, you can find it along with the initial root token value in the `.Vault Docker lab_node_1_init` file.

### Run a certain Vault version

Vault Docker lab offers the latest available Vault Docker image version, but you can also run a specific version of Vault for which an image exists with the `TF_VAR_vault_version` environment variable:

```shell
TF_VAR_vault_version=1.11.0 make
```

> **Tip**: You should use Vault versions >= 1.11.0 for ideal Integrated Storage support.

### Run Vault Enterprise

Vault Docker lab runs the Vault community edition by default, but you can also run the Enterprise edition.

> **NOTE**: You must have an [Enterprise license](https://www.hashicorp.com/products/vault/pricing) to run the Vault Enterprise image.

Export the `TF_VAR_vault_license` environment variable with your Vault Enterprise license string as the value. For example:

```shell
export TF_VAR_vault_license=02E2VCBORGUIRSVJVCECNSNI...
```

Export the `TF_VAR_vault_edition` environment variable to specify `vault-enterprise` as the value.

```shell
export TF_VAR_vault_edition=vault-enterprise
```

Make Vault Docker lab.

```shell
make
```

### Set the Vault server log level

The default Vault server log level is Info, but you can specify another log level like `Debug`, with the `TF_VAR_vault_log_level` environment variable like this:

```shell
TF_VAR_vault_log_level=Debug make
```

### Stage a cluster

By default, Vault Docker lab automatically initializes and unseals Vault. If you'd rather perform these steps yourself, you can specify that they're skipped.

Stage a cluster:

```shell
make stage
```

Example output:

```plaintext
[Vault Docker lab] Initializing Terraform workspace ...Done.
[Vault Docker lab] Applying Terraform configuration ...Done.
[Vault Docker lab] Export VAULT_ADDR for the active node: export VAULT_ADDR=https://127.0.0.1:8200
[Vault Docker lab] Vault is not initialized or unsealed. You must initialize and unseal Vault prior to use.
```

### Enable telemetry stack

After establishing the Vault Docker Lab, you can enable a telemetry gathering stack consisting of Prometheus and Grafana containers with this command instead of just `make`:

```shell
make telemetry
```

Example output:

```plaintext
👋 Hello from Vault Docker Lab
[+] Initializing Terraform workspace ...done.
[+] Applying Terraform configuration ...done.
[+] Check Vault active node status ...ok.
[+] Check Vault initialization status ...ok.
[+] Unsealing cluster nodes .....node 2. node 3. node 4. node 5. done.
[+] Enable audit device on vdl_node_1 in /vault/logs/vault_audit.log done.
[+] [Prometheus] initializing Terraform workspace ...done.
[+] [Prometheus] Applying Terraform configuration ...done.
[i] [Prometheus] web interface available at http://127.0.0.1:9090
[+] [Grafana] initializing Terraform workspace ...done.
[+] [Grafana] Applying Terraform configuration ...done.
[i] [Grafana] web interface available at http://127.0.0.1:3000

[i] Export VAULT_ADDR for the active node: export VAULT_ADDR=https://127.0.0.1:8200
[i] Login to Vault with initial root token: vault login hvs.rCKq3...c0ff33...HUxxvo7
```

### Docker resource usage

The screenshot shows a Vault Docker lab that has been up but idle for 25 minutes.

<img width="732" alt="Docker screenshot showing Vault Docker lab resource usage" src="https://github.com/hashicorp-education/learn-vault-docker-lab/assets/77563/5ff76eed-7c70-4bdd-bca2-3a478d878b10">

### Cleanup

To clean up Docker containers and all generated artifacts, **including audit device log files**:

```shell
make clean
```

Example output:

```plaintext
👋 Hello from Vault Docker Lab
[-] Destroying Terraform configuration ...done.
[-] Removing created artifacts ...done.
```

or, if you enabled the telemetry stack:

```shell
make clean-with-telemetry
```

Example output:

```plaintext
👋 Hello from Vault Docker Lab
[-] [Grafana] Destroying Terraform configuration ...done.
[-] [Grafana] Removing artifacts created by Vault Docker Lab ...done.
[-] [Prometheus] Destroying Terraform configuration ...done.
[-] [Prometheus] Removing artifacts created by Vault Docker Lab ...done.
[-] Destroying Terraform configuration ...done.
[-] Removing created artifacts ...done.
```

To clean up **everything** including Terraform runtime configuration and state:

```shell
make cleanest
```

Example output:

```plaintext
👋 Hello from Vault Docker Lab
[-] Destroying Terraform configuration ...done.
[-] Removing created artifacts ...done.
[-] Removing all Terraform runtime configuration and state ...done.
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
