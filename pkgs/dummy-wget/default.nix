{ stdenv, ... }:

stdenv.mkDerivation rec {
  name = "dummy-wget";

  src = ./wget.sh;

  phases = [ "installPhase" ];

  installPhase = ''
    mkdir -p $out/bin
    cp -v $src $out/bin/wget
    chmod +x $out/bin/wget
  '';
}
