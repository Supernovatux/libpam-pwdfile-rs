{
  config,
  withSystem,
  ...
}:
let
  pname = "libpam-pwdfile-rs";
in
{
  flake.overlays.${pname} =
    final: prev:
    withSystem prev.stdenv.hostPlatform.system (
      { config, ... }:
      {
        ${pname} = config.packages.${pname};
      }
    );

  flake.overlays.default = config.flake.overlays.${pname};
}
