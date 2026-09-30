# AGENTS.md

Guidelines for working on this repository. Human contributors and coding agents
should follow these rules.

## Project layout

- `src/` — Rust sources for the PAM module (`lib.rs`) and the SUID helper
  (`helper.rs`).
- `package.nix` — the derivation (`buildRustPackage`). Keep the `version` in
  sync with `Cargo.toml`.
- `packages.nix` — flake-parts module exposing the package as
  `perSystem.packages.libpam-pwdfile-rs` (and `.default`).
- `overlays.nix` — flake-parts module exposing `flake.overlays.libpam-pwdfile-rs`
  and `flake.overlays.default`.
- `nixosModules.nix` — flake-parts module exposing
  `flake.nixosModules.libpam-pwdfile-rs` and `flake.nixosModules.default`.
- `module.nix` — the actual NixOS module. Owns everything under
  `services.libpam-pwdfile-rs`.
- `flake.nix` — flake-parts entry point.

## Commands

- Enter the dev shell: `nix develop`
- Build the package: `nix build .#default` (alias of `.#libpam-pwdfile-rs`)
- Evaluate the flake: `nix flake check`
- Rust formatting/lints/tests:
  - `cargo fmt`
  - `cargo clippy --all-targets`
  - `cargo test`

When the Cargo dependency graph changes, `cargoHash` in `package.nix` must be
updated. Build once; Nix prints the correct `got: sha256-...` value in the
fixed-output hash mismatch error.

## Nix code guidelines

- **Use flake-parts.** New flake outputs go through flake-parts modules.
- **Never use the flake `self` argument.** It is unsound. Use
  `withSystem`, `moduleWithSystem`, the flake-parts `config` argument, or
  `_module.args.root` instead.
- **Root path:** `config._module.args.root = ./.` is set on the top-level
  flake-parts module. Note that flake-parts evaluates `perSystem` in a separate
  module scope, so the root is also set inside the `perSystem` module in
  `flake.nix`; refer to it as the `root` argument from per-system modules.
- **No activation scripts.** Do not use `system.activationScripts`. Generate
  runtime state with systemd mechanisms instead: `systemd.services` and
  `systemd.tmpfiles`.
- **Output conventions** for `pname = "libpam-pwdfile-rs"`:
  - `perSystem.packages.${pname}` and `perSystem.packages.default`
  - `flake.overlays.${pname}` (consumes the per-system package via
    `withSystem`) and `flake.overlays.default`
  - `flake.nixosModules.${pname}` (injects the per-system package via
    `withSystem` / `lib.mkDefault`) and `flake.nixosModules.default`
- The `nixpkgs` input tracks `nixos-unstable`.
- **NixOS options** live under `services.libpam-pwdfile-rs`:
  - `enable` — opt-in boolean (`lib.mkEnableOption`).
  - `package` — the package, with
    `defaultText = lib.literalExpression "pkgs.libpam-pwdfile-rs"`.
  - `instances.<name>.pamServices` — list of PAM services to authenticate.
  - `instances.<name>.users.<user>.hashedPassword` or
    `...users.<user>.hashedPasswordFile` — exactly one per user.
- **Secrets:** never read secret files at evaluation/activation time.
  `hashedPasswordFile` is read at boot by a systemd oneshot service (this is
  what supports secret managers such as sops-nix).
- **Deprecations:** rename with `mkRenamedOptionModule`, or map manually and
  emit `config.warnings` plus a `news.entries` entry. The `news` module no
  longer exists on `nixos-unstable`; guard news with
  `lib.optionalAttrs (options ? news) { ... }`.

## Version bumps

A release must keep the version in sync across:
`Cargo.toml`, `Cargo.lock` (the workspace `pam_pwdfile_rs` entry only),
`package.nix` (`version`, `changelog`, and `cargoHash`), `PKGBUILD`,
`pam_pwdfile_rs.spec` (including `%changelog`), and both `README.md` and
`README-CN.md`.

## Rust guidelines

- Edition 2024.
- Run `cargo fmt` and `cargo clippy --all-targets` before committing.
- Keep the PAM module and helper free of panics on the auth path.
