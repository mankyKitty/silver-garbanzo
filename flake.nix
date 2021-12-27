{
  description = "idris-template's description";

  inputs = {
    flake-utils.url = "github:numtide/flake-utils";
    flake-compat = {
      url = "github:edolstra/flake-compat";
      flake = false;
    };
    idris2-pkgs.url = "github:claymager/idris2-pkgs";
    nixpkgs.follows = "idris2-pkgs/nixpkgs";
  };
  outputs = inputs@{ self, nixpkgs, idris2-pkgs, flake-utils, ... }:
    flake-utils.lib.eachSystem [ "x86_64-linux" "x86_64-darwin" "aarch64-darwin" ] (system:
      let
        overlays = [
          idris2-pkgs.overlay
        ];
        pkgs = import nixpkgs {
          inherit system overlays;
          config.allowBroken = true;
        };

        inherit (pkgs.idris2-pkgs._builders) idrisPackage devEnv;

        elab-util = idrisPackage (import ./nix/sources.nix).idris2-elab-util {
          ipkgFile = "elab-util.ipkg";
        };
        sop = idrisPackage (import ./nix/sources.nix).idris2-sop {
          ipkgFile = "sop.ipkg";
        };
        dom = idrisPackage (import ./nix/sources.nix).idris2-dom {
          ipkgFile = "dom.ipkg";
          extraPkgs.sop = sop;
          extraPkgs.elab-util = elab-util;
        };

        silver-garbanzo = idrisPackage ./. {
          extraPkgs.dom = dom;
        };

        # runTests = idrisPackage ./tests {
        #   extraPkgs.silver-garbanzo = silver-garbanzo;
        # };

        project = returnShellEnv:
          pkgs.mkShell {
            packages = with pkgs; [
              # inherit mypkg
              # runTests
              idris2
              dom
              sop
              elab-util
              nixpkgs-fmt
              nodePackages.live-server
              goreman
              entr
              nodejs
              nodePackages.concurrently
            ];
            buildInputs = [
              (devEnv silver-garbanzo)
            ];
          };
      in
      {
        # Used by `nix build` & `nix run` (prod exe)
        # defaultPackage = project false;
        defaultPackage = silver-garbanzo;

        # Used by `nix develop` (dev shell)
        devShell = (project true).overrideAttrs (oa: {
          shellHook = oa.shellHook + ''
            export DYLD_LIBRARY_PATH=${pkgs.idris2}/lib:$DYLD_LIBRARY_PATH
          '';
        });
      });
}
