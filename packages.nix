{
  perSystem =
    {
      config,
      pkgs,
      root,
      ...
    }:
    let
      pname = "libpam-pwdfile-rs";
    in
    {
      packages.${pname} = pkgs.callPackage (root + "/package.nix") { };
      packages.default = config.packages.${pname};
    };
}
