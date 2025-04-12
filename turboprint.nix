{
  stdenv,
  fetchurl,
  rpm,
  cpio,
  autoPatchelfHook,
  makeWrapper,
  gtk2,
  gimp,
  lib,
  buildFHSEnv,
  ...
}:
let

  pname = "turboprint";
  version = "2.57-1";
  src = fetchurl {
    url = "https://www.zedonet.com/download/tp2/turboprint-${version}.x86_64.rpm";
    hash = "sha256-vluEWmgJcSSqAKLjG3Ony3yCRSEDKWXw9SWZsuX0ii8=";
  };
  meta = with lib; {
    homepage = "https://turboprint.info";
    description = "Turbo Print Drivers for High End Printers";
    platforms = platforms.linux;
  };

in

rec {
  turboprint = stdenv.mkDerivation {
    inherit
      pname
      version
      src
      meta
      ;
    dontUnpack = true;
    nativeBuildInputs = [
      rpm
      cpio
      autoPatchelfHook
      makeWrapper
    ];
    buildInputs = [
      gtk2
      gimp
    ];
    installPhase = ''
            runHook preInstall
      			pwd
      			mkdir -p $out
      			cd $out
      			rpm2cpio ${src} | cpio -imdv
      			mv $out/usr/bin $out/bin
      			mv $out/usr/share $out/share
      			mv $out/usr/lib $out/lib
      			rm -rf $out/usr
      			rm $out/lib/turboprint/gnomeapplet/tpgnomeapplet
      			wrapProgram $out/bin/turboprint
            runHook postInstall
      		'';
  };
  withEnv = buildFHSEnv {
    inherit pname version meta;
    targetPkgs = _: turboprint.buildInputs ++ [ turboprint ];
    runScript = "${turboprint}/bin/turboprint";
  };

  daemon = buildFHSEnv {
    pname = "tprintdaemon";
    inherit version meta;
    targetPkgs = _: turboprint.buildInputs ++ [ turboprint ];
    runScript = "${turboprint}/bin/tprintdaemon";
  };

}
