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
      };

      config = lib.mkIf cfg.enable {
        systemd.services.vintagestory-server = {
          description = "Vintage Story Server";
          after = [ "network.target" ];
          wantedBy = [ "multi-user.target" ];

          script = ''
            mkdir -p $(dirname ${toString cfg.dataPath})
            chmod 0750 $(dirname ${toString cfg.dataPath})

            ${lib.getExe' cfg.package "vintagestory-server"}
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
