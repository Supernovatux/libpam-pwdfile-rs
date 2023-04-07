# Maintainer: Supernovatux <thulashitharan.d@gmail.com>

pkgname=libpam-pwdfile-rs
pkgver=0.1.0
pkgrel=1
pkgdesc="A simple PAM module to authenticate users against a password file"
url="https://github.com/Supernovatux/libpam-pwdfile-rs"
license=("MIT")
arch=("x86_64")
provides=("libpam-pwdfile-rs")
conflicts=("libpam-pwdfile-rs")
source=("https://github.com/Supernovatux/$pkgname/releases/download/$pkgver/$pkgname-$pkgver-x86_64.tar.gz")
sha512sums=("3e961b01592ec79b2cbd56f1c79c23e166c3701bce6d7b965eede873450e9a2cd81e09200b9ecbef9e37e32fc5f80a7af9f5f9672782e1f34bc23ed080d21b0a")

package() {
    install -Dm755 "target/x86_64-unknown-linux-gnu/release/libpam_pwdfile_rs.so" "$pkgdir/usr/lib/security/pam_pwdfile_rs.so"
    install -Dm444 LICENSE "$pkgdir/usr/share/licenses/$pkgname/LICENSE"
}
