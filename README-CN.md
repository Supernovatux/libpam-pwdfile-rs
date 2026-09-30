# libpam-pwdfile-rs

[![Rust](https://img.shields.io/badge/Rust-1.85+-f74c00?style=flat-square&logo=rust)](https://www.rust-lang.org/)
[![NixOS](https://img.shields.io/badge/NixOS-Flake_Ready-5277C3?style=flat-square&logo=nixos)](https://nixos.org/)
[![Arch Linux](https://img.shields.io/badge/Arch_Linux-PKGBUILD-1793D1?style=flat-square&logo=archlinux)](https://archlinux.org/)
[![MIT License](https://img.shields.io/badge/License-MIT-green?style=flat-square)](LICENSE)
[![Version](https://img.shields.io/badge/v0.5.0-latest-blue?style=flat-square)](https://github.com/lialh4qwq/libpam-pwdfile-rs/releases/tag/v0.5.0)

**[English](README.md)**

---

> 🔐 **现代化的 PAM 模块** — 使用 **yescrypt** 保护的密码文件认证方案。

想给 `sudo` 或 `polkit` 设置独立的 PIN？想让不同服务使用不同密码？这个 PAM 模块让一切变得简单。

## ✨ 特性

基于 [Supernovatux/libpam-pwdfile-rs](https://github.com/Supernovatux/libpam-pwdfile-rs) 开发，增加了 yescrypt 支持和 NixOS 集成。

- 🛡️ **yescrypt 哈希** — 内存硬化，抗 GPU 破解
- 🐧 **NixOS 原生支持** — 包含 Flake 和声明式模块
- 📦 **多发行版** — Arch 的 PKGBUILD，Fedora/RHEL 的 RPM spec，其他发行版通用安装
- 🔧 **配置简单** — 密码文件只需 `用户名:哈希`
- 🔒 **SUID helper** — 支持非 root PAM 客户端（hyprlock 等）

## 🛡️ 为什么选择 yescrypt？

**yescrypt** 是一种现代密码哈希算法：
- 🧠 **内存硬化**：每次哈希需要大量内存，限制 GPU 并行能力
- ⏱️ **可调成本**：可根据安全需求调整时间/内存参数
- 🐧 **久经考验**：Debian、Ubuntu、Fedora、Arch 等发行版 `/etc/shadow` 的默认算法
- 🏆 **PHC 认可**：基于密码哈希竞赛决赛选手 scrypt

## 🚀 快速开始

### 生成密码哈希

```bash
mkpasswd -m yescrypt
# 输入密码后，你会得到类似这样的哈希：
# $y$j9T$F5Jx5fExrKuPp53xLKQ..1$X3DX6M94c7o.9agCG9G317fhZg9SqC.5i5rd.RhvU7D
```

### 安装

<details>
<summary><strong>🐧 NixOS（推荐）</strong></summary>

添加到你的 `flake.nix`：

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    libpam-pwdfile-rs = {
      url = "github:lialh4qwq/libpam-pwdfile-rs/v0.5.0";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { nixpkgs, libpam-pwdfile-rs, ... }: {
    nixosConfigurations.your-host = nixpkgs.lib.nixosSystem {
      modules = [
        # `nixosModules.default` 是 `nixosModules.libpam-pwdfile-rs` 的别名
        libpam-pwdfile-rs.nixosModules.default
        # ... 其他模块
      ];
    };
  };
}
```

然后配置：

```nix
services.libpam-pwdfile-rs = {
  enable = true;
  # 一个配置实例，名称任意
  instances.pin = {
    # 哪些 PAM 服务使用该实例认证
    pamServices = [ "polkit-1" "sudo" ];
    # 用户及其哈希后的密码
    users.yourname.hashedPassword = "$y$j9T$...";  # mkpasswd -m yescrypt
  };
};
```

密码文件会在启动时自动生成于 `/run/libpam-pwdfile-rs/<instance>`，无需手动管理。
若要从密钥管理器（如 [sops-nix](https://github.com/Mic92/sops-nix)）读取哈希，
改用 `hashedPasswordFile`：

```nix
services.libpam-pwdfile-rs.instances.pin.users.yourname.hashedPasswordFile =
  config.sops.secrets.pin-hash.path;
```

也可以使用 overlay，它把包暴露为 `pkgs.libpam-pwdfile-rs`（模块的 `package`
选项默认使用它）：

```nix
nixpkgs.overlays = [ libpam-pwdfile-rs.overlays.default ];
```

> **从 < 0.5.0 升级？** 该模块现在需要通过 `enable = true` 显式启用，旧的
> `libpam-pwdfile-rs.<name>` 选项已弃用但仍会被映射：`services` 变为
> `instances.<name>.pamServices`，`users.<user>.secret` 变为
> `users.<user>.hashedPassword`。会输出警告；在仍提供 `news` 模块的 NixOS
> 版本上还会显示 news 条目。

</details>

<details>
<summary><strong>🔷 Arch Linux</strong></summary>

```bash
# 下载并从源码构建
curl -LO https://github.com/lialh4qwq/libpam-pwdfile-rs/releases/download/v0.5.0/PKGBUILD
makepkg -si
```

</details>

<details>
<summary><strong>🎩 Fedora/RHEL</strong></summary>

```bash
# 下载 spec 文件并构建 RPM
curl -LO https://github.com/lialh4qwq/libpam-pwdfile-rs/releases/download/v0.5.0/pam_pwdfile_rs.spec
rpmbuild -ba pam_pwdfile_rs.spec
sudo dnf install ~/rpmbuild/RPMS/x86_64/pam_pwdfile_rs-*.rpm
```

</details>

<details>
<summary><strong>📦 其他发行版</strong></summary>

```bash
git clone https://github.com/lialh4qwq/libpam-pwdfile-rs
cd libpam-pwdfile-rs

# 构建（通过 .cargo/config.toml 使用 clang）
cargo build --release

# 安装 PAM 模块
sudo install -Dm755 target/release/libpam_pwdfile_rs.so /usr/lib/security/pam_pwdfile_rs.so

# 安装 helper（SUID root）
sudo install -Dm4755 target/release/pam_pwdfile_rs_helper /usr/bin/pam_pwdfile_rs_helper
```

</details>

## ⚙️ 配置（非 NixOS）

### 密码文件格式

创建密码文件（例如 `/etc/pwdfile`）：

```
alice:$y$j9T$abc123...$hashhashhash
bob:$y$j9T$def456...$hashhashhash
```

每行格式：`用户名:yescrypt哈希`

### PAM 集成

添加到 PAM 服务配置（例如 `/etc/pam.d/sudo`）：

```pam
#%PAM-1.0
auth    sufficient  pam_pwdfile_rs.so pwdfile /etc/pwdfile
auth    include     system-auth
account include     system-auth
session include     system-auth
```

`sufficient` 关键字的含义：如果认证成功，跳过后续认证直接通过；如果失败，继续尝试下一个认证方式。

**可选：** 指定自定义 helper 路径：

```pam
auth    sufficient  pam_pwdfile_rs.so pwdfile /etc/pwdfile helper=/custom/path/helper
```

## 🎯 使用场景

- 🔢 **polkit 的 PIN 码** — 用简短数字码进行图形界面提权
- 🔑 **独立的 sudo 密码** — 终端和登录使用不同密码
- 👥 **多密码用户** — 一个用户，多个有效密码
- 🏢 **服务账户** — 无需系统用户管理的简单认证

## 📝 许可证

MIT — 随便用。

---

<p align="center">
  <sub>用 🦀 Rust 打造</sub>
</p>
