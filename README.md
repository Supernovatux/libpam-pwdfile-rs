# libpam-pwdfile-rs

[![Rust](https://img.shields.io/badge/Rust-1.85+-f74c00?style=flat-square&logo=rust)](https://www.rust-lang.org/)
[![NixOS](https://img.shields.io/badge/NixOS-Flake_Ready-5277C3?style=flat-square&logo=nixos)](https://nixos.org/)
[![Arch Linux](https://img.shields.io/badge/Arch_Linux-PKGBUILD-1793D1?style=flat-square&logo=archlinux)](https://archlinux.org/)
[![MIT License](https://img.shields.io/badge/License-MIT-green?style=flat-square)](LICENSE)
[![Version](https://img.shields.io/badge/v0.5.0-latest-blue?style=flat-square)](https://github.com/lialh4qwq/libpam-pwdfile-rs/releases/tag/v0.5.0)

**[中文](README-CN.md)**

---

> 🔐 **A modern PAM module** for authenticating against password files — with **yescrypt** protection.

Ever wanted a separate PIN for `sudo` or `polkit`? Or different passwords for different services? This PAM module makes it simple.

## ✨ Features

Forked from [Supernovatux/libpam-pwdfile-rs](https://github.com/Supernovatux/libpam-pwdfile-rs), with yescrypt support and NixOS integration.

- 🛡️ **yescrypt hashing** — Memory-hard, GPU-resistant password protection
- 🐧 **NixOS native** — Flake + declarative module included
- 📦 **Multi-distro** — PKGBUILD for Arch, RPM spec for Fedora/RHEL, generic install for others
- 🔧 **Simple config** — Just `username:hash` in a file
- 🔒 **SUID helper** — Works with non-root PAM clients (hyprlock, etc.)

## 🛡️ Why yescrypt?

**yescrypt** is a modern password hashing algorithm:
- 🧠 **Memory-hard**: Each hash attempt needs significant RAM, limiting GPU parallelism
- ⏱️ **Tunable cost**: Adjustable time/memory parameters for your security needs
- 🐧 **Battle-tested**: Default for `/etc/shadow` on Debian, Ubuntu, Fedora, Arch...
- 🏆 **PHC-recognized**: Based on scrypt, a Password Hashing Competition finalist

## 🚀 Quick Start

### Generate a Password Hash

```bash
mkpasswd -m yescrypt
# Enter your password, get something like:
# $y$j9T$F5Jx5fExrKuPp53xLKQ..1$X3DX6M94c7o.9agCG9G317fhZg9SqC.5i5rd.RhvU7D
```

### Installation

<details>
<summary><strong>🐧 NixOS (Recommended)</strong></summary>

Add to your `flake.nix`:

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
        # `nixosModules.default` is an alias for `nixosModules.libpam-pwdfile-rs`
        libpam-pwdfile-rs.nixosModules.default
        # ... your other modules
      ];
    };
  };
}
```

Then configure:

```nix
services.libpam-pwdfile-rs = {
  enable = true;
  # a pwdfile instance, can be any name
  instances.pin = {
    # PAM services that authenticate against this instance
    pamServices = [ "polkit-1" "sudo" ];
    # users and their hashed passwords
    users.yourname.hashedPassword = "$y$j9T$...";  # mkpasswd -m yescrypt
  };
};
```

The pwdfile itself is generated at boot at `/run/libpam-pwdfile-rs/<instance>`,
so you do not need to manage it yourself. To source the hash from a secret
manager such as [sops-nix](https://github.com/Mic92/sops-nix), use
`hashedPasswordFile` instead:

```nix
services.libpam-pwdfile-rs.instances.pin.users.yourname.hashedPasswordFile =
  config.sops.secrets.pin-hash.path;
```

The overlay is available as well and exposes the package as
`pkgs.libpam-pwdfile-rs` (the module's `package` option defaults to it):

```nix
nixpkgs.overlays = [ libpam-pwdfile-rs.overlays.default ];
```

> **Upgrading from < 0.5.0?** The module is now opt-in via `enable = true`, the
> old `libpam-pwdfile-rs.<name>` options are deprecated but still mapped:
> `services` became `instances.<name>.pamServices` and `users.<user>.secret`
> became `users.<user>.hashedPassword`. A warning is emitted and, where the
> NixOS release still ships the `news` module, a news entry is shown.

</details>

<details>
<summary><strong>🔷 Arch Linux</strong></summary>

```bash
# Download and build from source
curl -LO https://github.com/lialh4qwq/libpam-pwdfile-rs/releases/download/v0.5.0/PKGBUILD
makepkg -si
```

</details>

<details>
<summary><strong>🎩 Fedora/RHEL</strong></summary>

```bash
# Download spec file and build RPM
curl -LO https://github.com/lialh4qwq/libpam-pwdfile-rs/releases/download/v0.5.0/pam_pwdfile_rs.spec
rpmbuild -ba pam_pwdfile_rs.spec
sudo dnf install ~/rpmbuild/RPMS/x86_64/pam_pwdfile_rs-*.rpm
```

</details>

<details>
<summary><strong>📦 Other Distros</strong></summary>

```bash
git clone https://github.com/lialh4qwq/libpam-pwdfile-rs
cd libpam-pwdfile-rs

# Build (uses clang via .cargo/config.toml)
cargo build --release

# Install PAM module
sudo install -Dm755 target/release/libpam_pwdfile_rs.so /usr/lib/security/pam_pwdfile_rs.so

# Install helper (SUID root)
sudo install -Dm4755 target/release/pam_pwdfile_rs_helper /usr/bin/pam_pwdfile_rs_helper
```

</details>

## ⚙️ Configuration (Non NixOS)

### Password File Format

Create your password file (e.g., `/etc/pwdfile`):

```
alice:$y$j9T$abc123...$hashhashhash
bob:$y$j9T$def456...$hashhashhash
```

Each line: `username:yescrypt_hash`

### PAM Integration

Add to your PAM service (e.g., `/etc/pam.d/sudo`):

```pam
#%PAM-1.0
auth    sufficient  pam_pwdfile_rs.so pwdfile /etc/pwdfile
auth    include     system-auth
account include     system-auth
session include     system-auth
```

The `sufficient` keyword means: if this succeeds, skip to the next stage. If it fails, try the next auth method.

**Optional:** Specify custom helper path:

```pam
auth    sufficient  pam_pwdfile_rs.so pwdfile /etc/pwdfile helper=/custom/path/helper
```

## 🎯 Use Cases

- 🔢 **PIN for polkit** — Quick numeric code for GUI privilege elevation
- 🔑 **Separate sudo password** — Different password for terminal vs login
- 👥 **Multi-password users** — One user, multiple valid passwords
- 🏢 **Service accounts** — Simple auth without system user management

## 📝 License

MIT — Do whatever you want.

---

<p align="center">
  <sub>Made with 🦀 Rust</sub>
</p>
