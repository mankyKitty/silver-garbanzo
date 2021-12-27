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

        silver-garbanzo = idrisPackage ./. { }; # this package
        # runTests = idrisPackage ./tests {
        #   extraPkgs.mypkg = mypkg;
        # };

        project = returnShellEnv:
          pkgs.mkShell {
            packages = with pkgs; [
              # inherit mypkg
              # runTests
              idris2
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
        defaultPackage = project false;

        # packages =
        #   {
        #     inherit silver-garbanzo;
        #   };

        # Used by `nix develop` (dev shell)
        devShell = (project true).overrideAttrs (oa: {
          shellHook = oa.shellHook + ''
            export DYLD_LIBRARY_PATH=${pkgs.idris2}/lib:$DYLD_LIBRARY_PATH
          '';
        });
      });
}
