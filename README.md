# Code

## jsdelivr 缓存清理

**注意：以下命令仅用于清理 jsdelivr 缓存，不用于执行脚本**

```bash
curl -sSL https://purge.jsdelivr.net/gh/caleee/code@main/shellscript/proxmoxve/create-vm.sh
```

## 使用清单

### Java 相关

#### jre-install.sh
```bash
curl -sSL https://raw.githubusercontent.com/caleee/code/refs/heads/main/shellscript/java/jre-install.sh | bash
```

```bash
curl -sSL https://cdn.jsdelivr.net/gh/caleee/code@main/shellscript/java/jre-install.sh | bash
```

```bash
curl -sSL https://cdn.gh-proxy.com/https://raw.githubusercontent.com/caleee/code/refs/heads/main/shellscript/java/jre-install.sh | bash
```

### Proxmox VE 相关

#### create-vm.sh
```bash
curl -sSL https://raw.githubusercontent.com/caleee/code/refs/heads/main/shellscript/proxmoxve/create-vm.sh | bash -s -- 151 2 4 20 19
```

```bash
curl -sSL https://cdn.jsdelivr.net/gh/caleee/code@main/shellscript/proxmoxve/create-vm.sh | bash -s -- 151 2 4 20 19
```

```bash
curl -sSL https://cdn.gh-proxy.com/https://raw.githubusercontent.com/caleee/code/refs/heads/main/shellscript/proxmoxve/create-vm.sh | bash -s -- 151 2 4 20 19
```

### Ubuntu Cloud Init 相关

#### setup.sh
```bash
curl -sSL https://raw.githubusercontent.com/caleee/code/refs/heads/main/shellscript/ubuntu-cloud-init/setup.sh | bash
```

```bash
curl -sSL https://cdn.jsdelivr.net/gh/caleee/code@main/shellscript/ubuntu-cloud-init/setup.sh | bash
```

```bash
curl -sSL https://cdn.gh-proxy.com/https://raw.githubusercontent.com/caleee/code/refs/heads/main/shellscript/ubuntu-cloud-init/setup.sh | bash
```

#### verify.sh
```bash
curl -sSL https://raw.githubusercontent.com/caleee/code/refs/heads/main/shellscript/ubuntu-cloud-init/verify.sh | bash
```

```bash
curl -sSL https://cdn.jsdelivr.net/gh/caleee/code@main/shellscript/ubuntu-cloud-init/verify.sh | bash
```

```bash
curl -sSL https://cdn.gh-proxy.com/https://raw.githubusercontent.com/caleee/code/refs/heads/main/shellscript/ubuntu-cloud-init/verify.sh | bash
```

#### scripts/01-core.sh（通过 setup.sh 执行）
```bash
curl -sSL https://raw.githubusercontent.com/caleee/code/refs/heads/main/shellscript/ubuntu-cloud-init/setup.sh | bash -s -- --no-runtime --no-storage
```

```bash
curl -sSL https://cdn.jsdelivr.net/gh/caleee/code@main/shellscript/ubuntu-cloud-init/setup.sh | bash -s -- --no-runtime --no-storage
```

```bash
curl -sSL https://cdn.gh-proxy.com/https://raw.githubusercontent.com/caleee/code/refs/heads/main/shellscript/ubuntu-cloud-init/setup.sh | bash -s -- --no-runtime --no-storage
```

#### scripts/02-runtime.sh（通过 setup.sh 执行）
```bash
curl -sSL https://raw.githubusercontent.com/caleee/code/refs/heads/main/shellscript/ubuntu-cloud-init/setup.sh | bash -s -- --no-storage
```

```bash
curl -sSL https://cdn.jsdelivr.net/gh/caleee/code@main/shellscript/ubuntu-cloud-init/setup.sh | bash -s -- --no-storage
```

```bash
curl -sSL https://cdn.gh-proxy.com/https://raw.githubusercontent.com/caleee/code/refs/heads/main/shellscript/ubuntu-cloud-init/setup.sh | bash -s -- --no-storage
```

#### scripts/03-storage.sh（通过 setup.sh 执行）
```bash
curl -sSL https://raw.githubusercontent.com/caleee/code/refs/heads/main/shellscript/ubuntu-cloud-init/setup.sh | bash -s -- --no-runtime
```

```bash
curl -sSL https://cdn.jsdelivr.net/gh/caleee/code@main/shellscript/ubuntu-cloud-init/setup.sh | bash -s -- --no-runtime
```

```bash
curl -sSL https://cdn.gh-proxy.com/https://raw.githubusercontent.com/caleee/code/refs/heads/main/shellscript/ubuntu-cloud-init/setup.sh | bash -s -- --no-runtime
```

#### scripts/04-vagrant-vmware-workstation-init.sh
```bash
curl -sSL https://raw.githubusercontent.com/caleee/code/refs/heads/main/shellscript/ubuntu-cloud-init/scripts/04-vagrant-vmware-workstation-init.sh | bash
```

```bash
curl -sSL https://cdn.jsdelivr.net/gh/caleee/code@main/shellscript/ubuntu-cloud-init/scripts/04-vagrant-vmware-workstation-init.sh | bash
```

```bash
curl -sSL https://cdn.gh-proxy.com/https://raw.githubusercontent.com/caleee/code/refs/heads/main/shellscript/ubuntu-cloud-init/scripts/04-vagrant-vmware-workstation-init.sh | bash
```

#### scripts/05-docker.sh
```bash
curl -sSL https://raw.githubusercontent.com/caleee/code/refs/heads/main/shellscript/ubuntu-cloud-init/scripts/05-docker.sh | bash
```

```bash
curl -sSL https://cdn.jsdelivr.net/gh/caleee/code@main/shellscript/ubuntu-cloud-init/scripts/05-docker.sh | bash
```

```bash
curl -sSL https://cdn.gh-proxy.com/https://raw.githubusercontent.com/caleee/code/refs/heads/main/shellscript/ubuntu-cloud-init/scripts/05-docker.sh | bash
```
