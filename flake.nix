{
  description = "pipewire-hs";

  inputs = {
    # Nix Inputs
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    hs-bindgen-src = {
      url = "github:well-typed/hs-bindgen";
      flake = false;
    };
  };

  outputs = {
    self,
    nixpkgs,
    hs-bindgen-src,
  }: let
    forAllSystems = function:
      nixpkgs.lib.genAttrs [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ] (system:
        function rec {
          inherit system;
          compilerVersion = "ghc984";
          pkgs = nixpkgs.legacyPackages.${system};
          hlib = pkgs.haskell.lib;

          fixes = hfinal: hprev: {
            debruijn = hlib.unmarkBroken hprev.debruijn;
            skew-list = hlib.dontCheck (hlib.unmarkBroken hprev.skew-list);
            # aeson tests require a different version of Diff
            # so we just don't pull in the tests
            aeson = hlib.dontCheck (hprev.aeson);
          };

          versions = hfinal: hprev: {
            Diff = hfinal.callHackage "Diff" "1.0.1.1" {};
            data-default = hfinal.callHackage "data-default" "0.8.0.1" {};
            # fourmolu = hfinal.callHackage "fourmolu" "0.17.0.0" {};
            # Cabal-syntax = hfinal.Cabal-syntax_3_12_1_0;
            # ghc-lib-parser = hfinal.ghc-lib-parser_9_10_1_20250103;
          };

          hsbindgen = hfinal: hprev: {
            hs-bindgen = hlib.dontCheck (hfinal.callCabal2nix "hs-bindgen" "${hs-bindgen-src}/hs-bindgen" {});
            hs-bindgen-runtime = hlib.dontCheck (hfinal.callCabal2nix "hs-bindgen-runtime" "${hs-bindgen-src}/hs-bindgen-runtime" {});
            ansi-diff = hfinal.callCabal2nix "ansi-diff" "${hs-bindgen-src}/ansi-diff" {};
            c-expr = hlib.dontCheck (hfinal.callCabal2nix "c-expr" "${hs-bindgen-src}/c-expr" {});
            clang = hlib.overrideCabal (hfinal.callCabal2nix "clang" "${hs-bindgen-src}/clang" {}) (
              old: {
                preConfigure = ''
                  export LLVM_PATH=${pkgs.libclang}/bin/llvm-config
                '';

                buildDepends =
                  (old.buildDepends or [])
                  ++ [
                    pkgs.libclang.dev
                    pkgs.pkg-config
                  ];
              }
            );
          };

          project = hfinal: hprev: {
            pipewire-hs = hfinal.callCabal2nix "pipewire-hs" ./. {};
          };

          # Apply overrides in the right order
          hsPkgs = pkgs.haskellPackages.extend (pkgs.lib.composeManyExtensions [
            fixes
            versions
            hsbindgen
            project
          ]);
        });
  in {
    # nix fmt
    formatter = forAllSystems ({pkgs, ...}: pkgs.alejandra);

    # nix develop
    devShell = forAllSystems ({
      hsPkgs,
      pkgs,
      ...
    }:
      hsPkgs.shellFor {
        # withHoogle = true;
        packages = p: [
          p.pipewire-hs
        ];
        buildInputs = with pkgs;
          [
            # hsPkgs.haskell-language-server
            haskellPackages.haskell-language-server
            haskellPackages.cabal-install
            cabal2nix
            haskellPackages.ghcid
            haskellPackages.fourmolu
            haskellPackages.cabal-fmt
            hsPkgs.hs-bindgen
            pipewire
            pkg-config
            libclang
          ]
          ++ (builtins.attrValues (import ./scripts.nix {s = pkgs.writeShellScriptBin;}));
      });

    # nix build
    packages = forAllSystems ({hsPkgs, ...}: {
      pipewire-hs = hsPkgs.pipewire-hs;
      default = hsPkgs.pipewire-hs;
    });

    # You can't build the pipewire-hs package as a check because of IFD in cabal2nix
    checks = {};

    # nix run
    apps = forAllSystems ({system, ...}: {
      pipewire-hs = {
        type = "app";
        program = "${self.packages.${system}.pipewire-hs}/bin/pipewire-hs";
      };
      default = self.apps.${system}.pipewire-hs;
    });
  };
}
