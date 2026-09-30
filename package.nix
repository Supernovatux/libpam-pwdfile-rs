{
  lib,
  pam,
  pkg-config,
  rustPlatform,
  stdenv,
  llvmPackages,
}:

rustPlatform.buildRustPackage {
  pname = "libpam-pwdfile-rs";
  version = "0.5.0";

  src = lib.cleanSource ./.;

  cargoHash = "sha256-JV2xEtTE7aEYwfN3NA2SKEpUSzLFzjmcrn+KAipVXLs=";

  nativeBuildInputs = [
    pkg-config
    llvmPackages.clang
  ];

  buildInputs = [
    pam
  ];

  dontCargoInstall = true;

  installPhase = ''
    runHook preInstall
    install -Dm755 \
      target/${stdenv.targetPlatform.rust.cargoShortTarget}/release/libpam_pwdfile_rs.so \
      $out/lib/security/pam_pwdfile_rs.so
    install -Dm755 \
      target/${stdenv.targetPlatform.rust.cargoShortTarget}/release/pam_pwdfile_rs_helper \
      $out/bin/pam_pwdfile_rs_helper
    runHook postInstall
  '';

  meta = {
    description = "PAM module that auth against pwdfile";
    longDescription = ''
      Rust port of libpam-pwdfile, a PAM module that auth against pwdfile.
      This is useful if you want to use a different password somewhere, eg. gdm, polkit,
      which behaves like PIN of Windows.
      It can also be used to set multiple passwords for users.
      Passwords should be hashed with yescrypt (mkpasswd -m yescrypt).
    '';
    homepage = "https://github.com/lialh4qwq/pam-pwdfile-rs";
    changelog = "https://github.com/lialh4qwq/pam-pwdfile-rs/releases/tag/v0.5.0";
    license = lib.licenses.mit;
    platforms = lib.platforms.linux;
  };
}
