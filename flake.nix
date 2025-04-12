{
  description = "Turboprint";

  # Nixpkgs / NixOS version to use.
  inputs = {
    nixpkgs.url = "nixpkgs/nixos-unstable";
    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    flake-utils = {
      url = "github:numtide/flake-utils";
    };
  };

  outputs =
    {
      self,
      flake-utils,
      nixpkgs,
      treefmt-nix,
      ...
    }:
    flake-utils.lib.eachSystem ["x86_64-linux"] (
      system:
      let
        replace_vars = { };
        treefmtEval = treefmt-nix.lib.evalModule pkgs ./fmt.nix;
        pkgs = nixpkgs.legacyPackages.${system};
        turboprint = pkgs.callPackage ./turboprint.nix { };

      in
      {
        packages = {
          inherit turboprint;
          default = turboprint;
        };
        formatter = treefmtEval.config.build.wrapper;

        nixosModules.default =
          { config, lib, ... }:
          {
            options.services.turboprint.enable = lib.mkEnableOption "Enable Turboprint Daemon";

            config = lib.mkIf config.services.turboprint.enable {
              environment.etc."turboprint/system.cfg".text = ''
                			TPBIN_BROWSER=firefox
                			TPFILE_PRINTCAP=/etc/printcap
                			TPPATH_CONFIG=/etc/turboprint
                			TPPATH_SHARE=${turboprint}/share/turboprint
                			TPPATH_SPOOL=/var/spool/lpd
                			TPPATH_BIN=${turboprint}/bin
                			TPPATH_FILTERS=${turboprint}/lib/turboprint
                			TPPATH_DOC=${turboprint}/share/doc/turboprint
                			TPPATH_LOG=/var/log
                			TPPATH_VAR=/var/spool
                			TPPATH_TEMP=/tmp
                			TPPATH_MAN=${turboprint}/share/man
                			TPPATH_CUPSDRIVER=/usr/share/cups/model
                			TPPATH_CUPSSETTINGS=/etc/cups/ppd
                			TPPATH_CUPSLIB=/usr/lib/cups
                			TPPATH_CUPSLIB64=/usr/lib64/cups
                			TPOWN_SPOOLDIR=lp
                			TPMOD_SPOOLDIR=0755
                			TPOWN_SPOOLFILE=lp
                			TPMOD_SPOOLFILE=0640
                			TPDAEMON_START=1
                			TPDAEMON_USER=lp
                			TPDAEMON_GROUP=lp
                			TPDAEMON_PORT=5552
                			TPDAEMON_SERVER=1
                			TPUSE_GSZEDO=1
                			TPCONVERT_PDF=0
                		'';

              systemd.services.turboprint = {
                wantedBy = [ "multi-user.target" ];
                serviceConfig = {
                  Restart = "always";
                  WorkingDirectory = "/var/lib/turboprint";
                  ExecStart = "${turboprint}/bin/tprintdaemon";
                };
              };
            };
          };
      }
    );
}
