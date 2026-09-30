{
  config,
  withSystem,
  ...
}:
let
  pname = "libpam-pwdfile-rs";
in
{
  flake.nixosModules.${pname} =
    { pkgs, lib, ... }:
    {
      imports = [ ./module.nix ];

      services.${pname}.package = lib.mkDefault (
        withSystem pkgs.stdenv.hostPlatform.system (
          { config, ... }:
          config.packages.${pname}
        )
      );
    };

  flake.nixosModules.default = config.flake.nixosModules.${pname};
}
