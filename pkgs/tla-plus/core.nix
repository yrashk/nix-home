# http://research.microsoft.com/en-us/um/people/lamport/tla/tools.html

{ lib, fetchzip, makeWrapper, stdenv, jre, ... }:

let

  mkModule = { name, version, java-main, meta }: stdenv.mkDerivation {

    name = "tla-plus-${name}-${version}";

    src = fetchzip {

      # Originally from https://tla.msr-inria.inria.fr/tlatoolbox/dist/tla.zip
      url = "https://github.com/chris-martin/tla-plus/raw/5c9786746f6a2ba74e031279eb858bd9a1c59613/tla.zip";

      sha256 = "1n4v2pnlbih8hgmchwb21wy9cwv59gb3jv0rj427jal3nyh2ay3b";
    };

    buildInputs = [ makeWrapper ];

    phases = [ "installPhase" ];

    installPhase = ''
      mkdir -pv "$out/bin"
      echo -e "${jre}/bin/java ${java-main} \"\$@\"" > "$out/bin/${name}"
      chmod +x "$out/bin/${name}"
      wrapProgram "$out/bin/${name}" --set CLASSPATH "$src"
    '';

    meta = {

      # http://research.microsoft.com/en-us/um/people/lamport/tla/license.html
      license = with lib.licenses; [ mit ];

    } // meta;

  };

  modules = {

    tlc = mkModule {
      name = "tlc";
      version = "2.08";
      java-main = "tlc2.TLC";
      meta = {
        homepage = "http://research.microsoft.com/en-us/um/people/lamport/tla/tlc.html";
        description = "The TLA+ Model Checker";
        longDescription = ''
          Model checker for specifications written in TLA+. TLA+ is a specification
          language based on TLA, the Temporal Logic of Actions.
        '';
      };
    };

    sany = mkModule {
      name = "sany";
      version = "2.1";
      java-main = "tla2sany.SANY";
      meta = {
        homepage = "http://research.microsoft.com/en-us/um/people/lamport/tla/sany.html";
        description = "The TLA+ Syntactic Analyzer";
        longDescription = ''
          Parser and semantic analyzer for the TLA+ specification language.
        '';
      };
    };

    pluscal = mkModule {
      name = "pluscal";
      version = "1.8";
      java-main = "pcal.trans";
      meta = {
        homepage = "http://research.microsoft.com/en-us/um/people/lamport/tla/pluscal.html";
        description = "The PlusCal Algorithm Language";
        longDescription = ''
          Algorithm language based on TLA+. A PlusCal algorithm is translated to a TLA+
          specification, which can be checked with the TLC model checker. An algorithm
          language is for writing algorithms, just as a programming language is for writing
          programs. Formerly called +CAL.
        '';
      };
    };

    tlatex = mkModule {
      name = "tlatex";
      version = "1.0";
      java-main = "tla2tex.TLA";
      meta = {
        homepage = "http://research.microsoft.com/en-us/um/people/lamport/tla/tlatex.html";
        description = "A Typesetter for TLA+ Specifications";
        longDescription = ''
          Uses the LaTeX document production system to typeset TLA+ specifications.
          TLA+ is a specification language based on TLA, the Temporal Logic of Actions.
        '';
      };
    };

  };

  all = with modules; [ tlc sany pluscal tlatex ];

in modules // { inherit all; }
