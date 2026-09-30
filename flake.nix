{
  description = "libpam-pwdfile-rs - PAM module that auth against pwdfile";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
  };

  outputs =
    inputs@{ flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [
        "x86_64-linux"
        "aarch64-linux"
      ];

      # Make the flake root available to modules without relying on the
      # unsound `self` argument.
      _module.args.root = ./.;

      imports = [
        ./packages.nix
        ./overlays.nix
        ./nixosModules.nix
      ];

      perSystem =
        { pkgs, ... }:
        {
          # flake-parts evaluates `perSystem` in a separate module scope, so
          # the top-level `_module.args.root` does not reach it. Expose it here
          # for the per-system flake modules (packages.nix, ...).
          _module.args.root = ./.;

          devShells.default = pkgs.mkShell {
            nativeBuildInputs = [
              pkgs.cargo
              pkgs.rustc
              pkgs.rustfmt
              pkgs.clippy
              pkgs.rust-analyzer
              pkgs.pkg-config
              pkgs.clang
            ];

            buildInputs = [
              pkgs.pam
            ];

            shellHook = ''
              echo "libpam-pwdfile-rs development environment"
              echo "Rust: $(rustc --version)"
              echo "Cargo: $(cargo --version)"
            '';
          };
        };
    };
}
