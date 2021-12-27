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

        idrisPkgs =
          if system == "aarch64-darwin"
          then import nixpkgs { system = "x86_64-darwin"; }  # Rosetta only, no M1 build available
          else pkgs;

        mypkg = idrisPackage ./. { }; # this package
        runTests = idrisPackage ./tests {
          extraPkgs.mypkg = mypkg;
        };

        project = returnShellEnv:
          pkgs.mkShell {
            buildInputs = [
              (devEnv mypkg)
            ];
          };
      in
      {
        packages = with pkgs; [
          mypkg
          runTests
          idrisPkgs.idris2
          nixpkgs-fmt
          nodePackages.live-server
          goreman
          entr
          nodejs
          nodePackages.concurrently
        ];
        # Used by `nix build` & `nix run` (prod exe)
        defaultPackage = project false;

        # Used by `nix develop` (dev shell)
        devShell = (project true).overrideAttrs (oa: {
          shellHook = oa.shellHook + ''
            export DYLD_LIBRARY_PATH=${idrisPkgs.idris2}/lib:$DYLD_LIBRARY_PATH
          '';
        });
      });
}
