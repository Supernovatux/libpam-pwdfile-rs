#!/bin/zsh
pkgname=libpam-pwdfile-rs
cargo +nightly build -Z build-std=std,panic_abort -Z build-std-features=panic_immediate_abort --target x86_64-unknown-linux-gnu --release
version=$(cat Cargo.toml | grep -m1 version | awk '{print $3}' | tr -d '"')
tar -cvf $pkgname-$version-x86_64.tar.gz target/x86_64-unknown-linux-gnu/release/libpam_pwdfile_rs.so LICENSE -I "gzip --best"
shasum=$(sha512sum ./$pkgname-$version-x86_64.tar.gz | awk '{print $1}')
sed -i "s/sha512sums=.*/sha512sums=(\"$shasum\")/" PKGBUILD
sed -i "s/pkgver=.*/pkgver=$version/" PKGBUILD
