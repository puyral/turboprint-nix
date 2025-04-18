{ mkEnv, ... }:
{ config, lib, ... }:
let
  cfg = config.services.turboprint;
in
{
  options.services.turboprint = with lib; {
    enable = mkEnableOption "Enable Turboprint Daemon";
    deamon = {
      user = mkOption {
        type = types.str;
        default = "lp";
      };
      group = mkOption {
        type = types.str;
        default = "lp";
      };
    };
    browser = mkOption {
      type = types.str;
      default = "firefox";
    };
  };

  config =
    let
      mkPath =
        { name, path, ... }:
        let
          drv = mkEnv name (tb: "${tb}/${path}");
        in
        "${drv}/bin/${name}";

    in
    lib.mkIf cfg.enable {
      environment.etc."turboprint/system.cfg".text = ''
        			TPBIN_BROWSER=${cfg.browser}
        			TPFILE_PRINTCAP=/etc/printcap
        			TPPATH_CONFIG=/etc/turboprint
        			TPPATH_SPOOL=/var/spool/lpd
        			TPPATH_LOG=/var/log
        			TPPATH_VAR=/var/spool
        			TPPATH_TEMP=/tmp
        			TPPATH_CUPSDRIVER=/usr/share/cups/model
        			TPPATH_CUPSSETTINGS=/etc/cups/ppd
        			TPPATH_CUPSLIB=/usr/lib/cups
        			TPPATH_CUPSLIB64=/usr/lib64/cups
        			TPOWN_SPOOLDIR=${cfg.deamon.user}
        			TPMOD_SPOOLDIR=0755
        			TPOWN_SPOOLFILE=${cfg.deamon.user}
        			TPMOD_SPOOLFILE=0640
        			TPDAEMON_START=1
        			TPDAEMON_USER=${cfg.deamon.user}
        			TPDAEMON_GROUP=${cfg.deamon.group}
        			TPDAEMON_PORT=5552
        			TPDAEMON_SERVER=1
        			TPUSE_GSZEDO=1
        			TPCONVERT_PDF=0
        		'';

      systemd.services.turboprint =
        let
          tbd =
            c:
            mkPath {
              name = "tpdaemon-${c}";
              path = "lib/turboprint/tpdaemon ${c}";
            };
        in
        {
          enable = true;
          wantedBy = [ "multi-user.target" ];
          description = "Turboprint Monitor Daemon";
          after = [ "cups.service" ];
          serviceConfig = {
            Type = "forking";
            Restart = "on-failure";
            PIDFile = "/var/spool/turboprint/tpdaemon.pid";
            RemainAfterExit = "no";
            ExecStart = tbd "start";
            ExecStop = tbd "stop";
            ExecReload = tbd "restart";
          };
        };
      systemd.user.services.turboprint.user = {
        enable = true;
        wantedBy = [ "default.target" ];
        description = "Turboprint User Service";
        serviceConfig = {
          Type = "oneshot";
          ExecStart = mkPath {
            name = "95turboprint_monitor";
            path = "lib/turboprint/95turboprint_monitor";
          };
          RemainAfterExit = "yes";
        };

      };
    };
}

# [Unit]
# Description=Turboprint Monitor Daemon
# After=cups.service

# [Service]
# Type=forking
# Restart=on-failure
# RemainAfterExit=no
# PIDFile=/var/spool/turboprint/tpdaemon.pid
# ExecStart=/usr/lib/turboprint/tpdaemon start
# ExecStop=/usr/lib/turboprint/tpdaemon stop
# ExecReload=/usr/lib/turboprint/tpdaemon restart

# [Install]
# WantedBy=multi-user.target
