{ lib, fetchurl, makeWrapper, stdenv, ocaml, gawk, isabelle2011-1, cvc3, perl
, dummy-wget, ... }:

let

  version = "1.4.3";

  src = fetchurl {
    url = "https://tla.msr-inria.inria.fr/tlaps/dist/${version}/tlaps-${version}.tar.gz";
    sha256 = "1w5z3ns5xxmhmp8r4x2kjmy3clqam935gmvx82imyxrr1bamx6gf";
  };

  mkModule = { name, meta }: args:
    stdenv.mkDerivation (args // {

      name = "tlaps-${name}-${version}";

      inherit src;

      preConfigure = "cd ${name}";

      meta = {
        homepage = "http://tla.msr-inria.inria.fr/tlaps/content/Home.html";

        # https://tla.msr-inria.inria.fr/tlaps/content/Download/License.html
        license = with lib.licenses; [ bsd2 ];

      } // meta;

    });

  modules = {

    isabelle = mkModule {
      name = "isabelle";
      meta = {};
    } {
      buildInputs = [ ocaml isabelle2011-1 cvc3 perl ];
      buildPhase = "#";
      installPhase = ''
        runHook preBuild

        mkdir -pv "$out"
        export HOME="$out"

        pushd "${isabelle2011-1}/Isabelle2011-1/src/Pure"
        isabelle make
        popd

        # Use a modified version of the command in the Makefile
        # that avoids needing LaTeX dependencies
        isabelle usedir -b -i true Pure TLA+

        runHook postBuild
      '';
    };

    zenon = mkModule {
      name = "zenon";
      meta = {};
    } {
      buildInputs = [ ocaml ];
      configurePhase = ''
        runHook preConfigure
        ./configure --prefix "$out"
        runHook postConfigure
      '';
    };

    tlapm = mkModule {
      name = "tlapm";
      meta = {
        description = "The TLA+ Proof System (TLAPS)";
        longDescription = ''
          Mechanically checks TLA+ proofs. TLA+ is a general-purpose formal specification
          language that is particularly useful for describing concurrent and distributed
          systems. The TLA+ proof language is declarative, hierarchical, and scalable to
          large system specifications. It provides a consistent abstraction over the
          various "backend" verifiers. The current release of TLAPS does not perform
          temporal reasoning, and it does not handle some features of TLA+.
        '';
      };
    } {

      buildInputs = [ makeWrapper ocaml gawk dummy-wget ];

      configurePhase = ''
        runHook preConfigure
        ./configure --prefix $out
        runHook postConfigure
      '';

      postInstall = with modules; ''
        wrapProgram "$out/bin/tlapm" \
          --prefix PATH : "${isabelle}/bin:${zenon}/bin"
      '';
    };

  };

  all = with modules; [ tlapm isabelle zenon ];

in modules // { inherit all; }
