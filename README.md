# libpam-pwdfile-rs

## Description
This is a rust port of [libpam-pwdfile](https://git.tiwe.de/libpam-pwdfile.git). It is a PAM module that allows you to authenticate against a password file. Passwords should be hashed with sha512sum

## Use case
This module is useful if you want to authenticate with a password different from the one you use to login to your system. For example, if you want to use different password for SDDM and sudo.

## Installation

### Arch Linux

```bash
cd /tmp
wget https://github.com/Supernovatux/libpam-pwdfile-rs/releases/download/0.1.0/PKGBUILD
makepkg -si
```

### Other distributions

```bash
git clone https://github.com/Supernovatux/libpam-pwdfile-rs
cd libpam-pwdfile-rs
cargo build --release
sudo cp target/release/libpam_pwdfile_rs.so /usr/lib/security/pam_pwdfile_rs.so
```

## Configuration

Say you want to use custom password for users `foo` and `bar` with the password `password_foo` and `password_bar` respectively. You can create a file `/etc/pam.d/pwdfile` with the following content

```console
$ printf "password_foo" | sha512sum | awk '{print $1}' |  sed 's/.*/foo:&/' | sudo tee -a /etc/pwdfile
foo:c717e50d9dd5fb98877de7972daffa0f331e00496684f2d99642994cc777b6258df9a6397ecdf52456972e0fcf46104f4809a99d53102e6c7c70186b88263007
$ printf "password_bar" | sha512sum | awk '{print $1}' |  sed 's/.*/bar:&/' | sudo tee -a /etc/pwdfile
bar:9603f874c66bbcdac59b0f3ed6ebf510d10fcebc588e7712bfbae5eec687dfb134470ca98c74d55bed8368012706038874e108bb3ae876cdaf8206715274e442
$ sudo cat /etc/pwdfile
foo:c717e50d9dd5fb98877de7972daffa0f331e00496684f2d99642994cc777b6258df9a6397ecdf52456972e0fcf46104f4809a99d53102e6c7c70186b88263007
bar:9603f874c66bbcdac59b0f3ed6ebf510d10fcebc588e7712bfbae5eec687dfb134470ca98c74d55bed8368012706038874e108bb3ae876cdaf8206715274e442
```

Then if you want to use this password for sudo the file `/etc/pam.d/sudo` should look like this

```console
$ cat /etc/pam.d/sudo
#%PAM-1.0
auth        sufficient  pam_pwdfile_rs.so pwdfile /etc/pwdfile
auth        include     system-auth
account     include     system-auth
session     include     system-auth
```

Similarly, for other PAM services, you can prepend the line 
`auth        sufficient  pam_pwdfile_rs.so pwdfile /etc/pwdfile`
to the file `/etc/pam.d/<service>`.

## Uninstallation

You may want to undo the changes to pam.d directory first
### Arch Linux
```bash
$ sudo pacman -Rns libpam-pwdfile-rs
```

### Other distributions

```bash
$ sudo rm /usr/lib/security/pam_pwdfile_rs.so
```
