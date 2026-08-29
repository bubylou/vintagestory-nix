{
  flake.nixosModules.vintagestory-server =
    {
      pkgs,
      lib,
      config,
      ...
    }:
    let
      cfg = config.services.vintagestory-server;
    in
    {
      options.services.vintagestory-server = {
        enable = lib.mkEnableOption "Vintagestory server";
        package = lib.mkPackageOption pkgs "vintagestory-server" { };

        user = lib.mkOption {
          type = lib.types.str;
          default = "vintagestory";
        };

        group = lib.mkOption {
          type = lib.types.str;
          default = "vintagestory";
        };

        dataPath = lib.mkOption {
          type = lib.types.str;
          default = "/var/lib/vintagestory/data";
        };

        mods = lib.mkOption {
          enable = lib.mkEnableOption "enable mod support";
          type = lib.types.submodule {
            options = {
              name = lib.mkOption {
                type = lib.types.str;
                example = "CarryOn";
              };
              id = lib.mkOption {
                type = lib.types.int;
                example = "94053";
              };
              version = lib.mkOption {
                type = lib.types.str;
                example = "1.22.0_v1.14.2";
              };
              hash = lib.mkOption {
                type = lib.types.str;
                example = "sha256-abcd...";
              };
            };
          };
        };
      };

      config = lib.mkIf cfg.enable {
        systemd.services.vintagestory-server = {
          description = "Vintage Story Server";
          after = [ "network.target" ];
          wantedBy = [ "multi-user.target" ];

          script =
            let
              # list of name and url pairs of mods
              modList = [
                (lib.map (
                  source:
                  lib.nameValuePair cfg.mod.pname (
                    pkgs.fetchurl {
                      url = "https://mods.vintagestory.at/download/${source.id}/${source.name}-${source.version}.zip";
                    }
                  )
                ))
              ];

              flags = lib.mkIf cfg.mods.enable ("${lib.concatStringsSep " --addModPath " modList}");
            in
            ''
              mkdir -p $(dirname ${toString cfg.dataPath})
              chmod 0750 $(dirname ${toString cfg.dataPath})

              ${lib.getExe' cfg.package "vintagestory-server"} ${flags}
            '';

          serviceConfig = {
            User = cfg.user;
            Group = cfg.group;

            Restart = "on-failure";
            RestartSec = 10;
            StartLimitBurst = 5;

            StateDirectory = cfg.dataPath;
            StandardOutput = "journal";
            StandardError = "journal";
          };
        };

        users.users = lib.mkIf (cfg.user == "vintagestory") {
          vintagestory = {
            inherit (cfg) group;
            home = cfg.dataPath;
            isSystemUser = true;
          };
        };

        users.groups = lib.mkIf (cfg.group == "vintagestory") {
          vintagestory = { };
        };
      };
    };
}
