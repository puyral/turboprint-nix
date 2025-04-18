{ daemon, ... }:
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

  config = lib.mkIf cfg.enable {
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

    systemd.services.turboprint = {
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        Restart = "always";
        StateDirectory = "turboprint";
        WorkingDirectory = "/var/lib/turboprint";
        ExecStart = "${daemon}/bin/tprintdaemon";
      };
    };
  };
}
