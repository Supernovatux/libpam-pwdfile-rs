{
  config,
  lib,
  options,
  ...
}:
let
  pname = "libpam-pwdfile-rs";
  cfg = config.services.${pname};

  pwdfileDir = "/run/libpam-pwdfile-rs";
  pwdfilePath = name: "${pwdfileDir}/${name}";

  # Deprecated pre-0.5.0 option tree, kept only for migration.
  oldCfg = config.libpam-pwdfile-rs;
  hasOld = oldCfg != { };

  userType = lib.types.submodule {
    options = {
      hashedPassword = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        example = "$y$j9T$F5Jx5fExrKuPp53xLKQ..1$X3DX6M94c7o.9agCG9G317fhZg9SqC.5i5rd.RhvU7D";
        description = ''
          Password hashed with yescrypt (use: `mkpasswd -m yescrypt`).
          Mutually exclusive with {option}`hashedPasswordFile`.
        '';
      };
      hashedPasswordFile = lib.mkOption {
        type = lib.types.nullOr lib.types.path;
        default = null;
        example = "/run/secrets/pwdfile-hash";
        description = ''
          Path to a file containing the yescrypt hash. The file is read at boot
          by the pwdfile assembly service, which makes it suitable for secret
          managers such as sops-nix.
          Mutually exclusive with {option}`hashedPassword`.
        '';
      };
    };
  };

  instanceType = lib.types.submodule {
    options = {
      pamServices = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
        example = [
          "gdm"
          "polkit-1"
        ];
        description = "PAM services to enable authentication against this instance's pwdfile for.";
      };
      users = lib.mkOption {
        type = lib.types.attrsOf userType;
        default = { };
        example = {
          yourname.hashedPassword = "$y$j9T$F5Jx5fExrKuPp53xLKQ..1$X3DX6M94c7o.9agCG9G317fhZg9SqC.5i5rd.RhvU7D";
        };
        description = "Users and their hashed passwords used for authentication.";
      };
    };
  };

  # One shell statement per user, writing a `username:hash` line.
  mkUserLine =
    userName: user:
    if user.hashedPassword != null then
      "printf '%s:%s\\n' ${lib.escapeShellArg userName} ${lib.escapeShellArg user.hashedPassword}"
    else
      ''
        printf '%s:' ${lib.escapeShellArg userName}
        tr -d '\n' < ${lib.escapeShellArg (toString user.hashedPasswordFile)}
        printf '\n'
      '';

  mkAssemblyScript =
    name: inst:
    ''
      umask 077
      install -d -m 0700 ${pwdfileDir}
      {
      ${lib.concatLines (lib.mapAttrsToList (userName: user: mkUserLine userName user) inst.users)}
      } > ${lib.escapeShellArg (pwdfilePath name)}
    '';

  migrateInstance =
    inst:
    {
      pamServices = inst.services;
      users = lib.mapAttrs (_: user: { hashedPassword = user.secret; }) inst.users;
    };

  userAssertions = lib.flatten (
    lib.mapAttrsToList (
      name: inst:
      lib.mapAttrsToList (userName: user: {
        assertion = (user.hashedPassword == null) != (user.hashedPasswordFile == null);
        message = "services.${pname}.instances.${name}.users.${userName}: set exactly one of `hashedPassword` or `hashedPasswordFile`.";
      }) inst.users
    ) cfg.instances
  );
in
{
  options.services.${pname} = {
    enable = lib.mkEnableOption "the ${pname} PAM module";

    package = lib.mkOption {
      type = lib.types.package;
      defaultText = lib.literalExpression "pkgs.${pname}";
      description = ''
        The ${pname} package providing `pam_pwdfile_rs.so` and
        `pam_pwdfile_rs_helper`. Defaults to the package exposed by this flake's
        overlay (`pkgs.${pname}`).
      '';
    };

    instances = lib.mkOption {
      type = lib.types.attrsOf instanceType;
      default = { };
      example = {
        pin = {
          pamServices = [
            "gdm"
            "polkit-1"
          ];
          users.yourname.hashedPassword = "$y$j9T$...";
        };
      };
      description = "Pwdfile instances used to authenticate.";
    };
  };

  # Deprecated pre-0.5.0 options. They are translated to the new options below.
  options.libpam-pwdfile-rs = lib.mkOption {
    type = lib.types.attrsOf (
      lib.types.submodule {
        options = {
          pwdfile = lib.mkOption {
            type = lib.types.path;
            default = /etc/pwdfile;
            visible = false;
            description = "Deprecated and ignored. The pwdfile is managed at ${pwdfileDir}/<name>.";
          };
          services = lib.mkOption {
            type = lib.types.listOf lib.types.str;
            default = [ ];
            description = "Deprecated. Use {option}`services.${pname}.instances.<name>.pamServices`.";
          };
          users = lib.mkOption {
            type = lib.types.attrsOf (
              lib.types.submodule {
                options.secret = lib.mkOption {
                  type = lib.types.str;
                  default = "";
                  description = "Deprecated. Use {option}`services.${pname}.instances.<name>.users.<user>.hashedPassword`.";
                };
              }
            );
            default = { };
            description = "Deprecated. Use {option}`services.${pname}.instances.<name>.users`.";
          };
        };
      }
    );
    default = { };
    visible = false;
    description = "Deprecated options, use {option}`services.${pname}` instead.";
  };

  config = lib.mkMerge [
    {
      warnings =
        lib.optional hasOld ''
          The `libpam-pwdfile-rs.*` options are deprecated. Use
          `services.${pname}.enable = true` together with
          `services.${pname}.instances.<name>.pamServices` and
          `services.${pname}.instances.<name>.users.<user>.hashedPassword`.
        ''
        ++ lib.flatten (
          lib.mapAttrsToList (
            name: inst:
            lib.optional (inst.pwdfile != /etc/pwdfile)
              "libpam-pwdfile-rs.${name}.pwdfile is deprecated and has no effect. The pwdfile is managed at ${pwdfilePath name}."
          ) oldCfg
        );

      services.${pname} = {
        enable = lib.mkIf hasOld true;
        instances = lib.mkIf hasOld (lib.mapAttrs (_: migrateInstance) oldCfg);
      };
    }

    # NixOS removed the `news` module on unstable; only emit an entry where the
    # option still exists (e.g. NixOS 25.11).
    (lib.optionalAttrs (options ? news) {
      news.entries = lib.optional hasOld {
        time = "2026-09-30";
        condition = true;
        message = ''
          libpam-pwdfile-rs: the NixOS options have been renamed.

          `libpam-pwdfile-rs.<instance>.services` -> `services.${pname}.instances.<instance>.pamServices`
          `libpam-pwdfile-rs.<instance>.users.<user>.secret` -> `services.${pname}.instances.<instance>.users.<user>.hashedPassword`

          The module is now opt-in via `services.${pname}.enable = true`, and
          `users.<user>.hashedPasswordFile` can be used for secret managers.
        '';
      };
    })

    (lib.mkIf cfg.enable {
      assertions = userAssertions;

      security.wrappers.pam_pwdfile_rs_helper = {
        source = "${cfg.package}/bin/pam_pwdfile_rs_helper";
        setuid = true;
        owner = "root";
        group = "root";
      };

      security.pam.services = lib.mkMerge (
        lib.mapAttrsToList (
          name: inst:
          lib.genAttrs inst.pamServices (serviceName: {
            rules.auth.pwdfile = {
              # Run before pam_unix (sufficient: skip remaining auth rules if success)
              order = config.security.pam.services.${serviceName}.rules.auth.unix.order - 50;
              control = "sufficient";
              modulePath = "${cfg.package}/lib/security/pam_pwdfile_rs.so";
              args = [
                "pwdfile"
                (pwdfilePath name)
              ];
            };
          })
        ) cfg.instances
      );

      # Create the directory holding the generated pwdfiles.
      systemd.tmpfiles.settings."10-libpam-pwdfile-rs" = {
        "${pwdfileDir}".d = {
          mode = "0700";
          user = "root";
          group = "root";
        };
      };

      # Assemble each pwdfile at boot. Using a service (rather than an
      # activation script) keeps the module compatible with cross-compilation
      # and allows hashedPasswordFile to reference runtime secrets.
      systemd.services = lib.mapAttrs' (
        name: inst:
        lib.nameValuePair "libpam-pwdfile-rs-${name}" {
          description = "Assemble the ${pname} pwdfile for instance ${name}";
          wantedBy = [ "multi-user.target" ];
          before = [ "multi-user.target" ];
          after = [ "systemd-tmpfiles-setup.service" ];
          serviceConfig = {
            Type = "oneshot";
            RemainAfterExit = true;
          };
          script = mkAssemblyScript name inst;
        }
      ) cfg.instances;
    })
  ];
}
