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

To use custom passwords for specific users, create a file at `/etc/pwdfile` and add the hashed passwords for each user in the format `username:passwordhash`. You can use the `sha512sum `command to generate the hash of the password you want to use. For example, to use the password `password_foo` for user `foo`, run the command:
```console
$ echo -n "password_foo" | sha512sum
```
This will output the hash in the format `<hash> -`, where `<hash>` is the generated password hash. Copy the hash and paste it in the `/etc/pwdfile` file in the format `foo:<hash>`. Repeat this process for each user and password combination you want to set. You may use this command to automate the above process `printf "password_foo" | sha512sum | awk '{print $1}' |  sed 's/.*/$ foo:&/' | sudo tee -a /etc/pwdfile`

Say you want to use custom password for two users `foo` and `bar` with the password `password_foo` and `password_bar` respectively.Then your `/etc/pwdfile` should look like below

```console
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
