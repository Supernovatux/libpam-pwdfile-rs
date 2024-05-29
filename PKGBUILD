# Maintainer: Supernovatux <thulashitharan.d at gmail dot com>

pkgname=libpam-pwdfile-rs-bin
_pkgname=libpam-pwdfile-rs
pkgver=0.2.0
pkgrel=1
pkgdesc="A simple PAM module to authenticate users against a password file"
url="https://github.com/Supernovatux/libpam-pwdfile-rs"
license=("MIT")
arch=("x86_64")
provides=("libpam-pwdfile-rs")
conflicts=("libpam-pwdfile-rs")
depends=("pam")
source=("https://github.com/Supernovatux/$_pkgname/releases/download/v$pkgver/$_pkgname-$pkgver-$CARCH.tar.gz")
sha512sums=("6b881e53b74724c5f715bb7f36b78d994398a81f453191c4cd5beb6954c20e513d030dfeec8ad61f40b702adfdee0ada1cf17146bb809f10266595eb2fa0ce2d")

package() {
    install -Dm755 "target/$CARCH-unknown-linux-gnu/release/libpam_pwdfile_rs.so" "$pkgdir/usr/lib/security/pam_pwdfile_rs.so"
    install -Dm444 LICENSE "$pkgdir/usr/share/licenses/$pkgname/LICENSE"
}
