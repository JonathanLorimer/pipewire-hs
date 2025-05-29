{
  description = "pipewire-hs";

  inputs = {
    # Nix Inputs
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
  };

  outputs = {
    self,
    nixpkgs,
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
          hsPkgs = pkgs.haskellPackages.override {
            overrides = hfinal: hprev: {
              pipewire-hs = hfinal.callCabal2nix "pipewire-hs" ./. {};
            };
          };
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
            hsPkgs.haskell-language-server
            haskellPackages.cabal-install
            cabal2nix
            haskellPackages.ghcid
            haskellPackages.fourmolu
            haskellPackages.cabal-fmt
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
