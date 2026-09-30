# Maintainer: LiAlH4qwq <lialh4qwq@outlook.com>
pkgname=libpam-pwdfile-rs
pkgver=0.5.0
pkgrel=1
pkgdesc="PAM module for password file authentication with yescrypt"
url="https://github.com/lialh4qwq/libpam-pwdfile-rs"
license=("MIT")
arch=("x86_64")
depends=("pam")
makedepends=("cargo" "rust" "clang")
source=("$pkgname-$pkgver.tar.gz::https://github.com/lialh4qwq/$pkgname/archive/v$pkgver.tar.gz")
sha256sums=("SKIP")

build() {
    cd "$pkgname-$pkgver"
    cargo build --release --locked
}

package() {
    cd "$pkgname-$pkgver"

    # Install PAM module
    install -Dm755 "target/release/libpam_pwdfile_rs.so" \
        "$pkgdir/usr/lib/security/pam_pwdfile_rs.so"

    # Install helper (SUID root)
    install -Dm4755 "target/release/pam_pwdfile_rs_helper" \
        "$pkgdir/usr/bin/pam_pwdfile_rs_helper"

    # Install license
    install -Dm644 LICENSE "$pkgdir/usr/share/licenses/$pkgname/LICENSE"
}
