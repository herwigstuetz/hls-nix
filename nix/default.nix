{ sources ? import ./sources.nix
, system ? builtins.currentSystem
}:
let
  haskellnix = import sources."haskell.nix";
  overlay = _: pkgs:
    let
      mkPackages = { ghc, stackYaml }:
        pkgs.haskell-nix.stackProject {
            src = pkgs.fetchFromGitHub {
              owner = "korayal";
              repo = "haskell-language-server";
              rev = "2284facb9f06d05055cef88dcaffc24a1ce8255c";
              sha256 = "0y9q940i5n1q7fwx5cvgmh3x7v00320i34rfa39chwmb8csyp7w1";
              fetchSubmodules = true;
            };
            inherit stackYaml;
            modules = [({config, ...}: {
              ghc.package = ghc;
              compiler.version = pkgs.lib.mkForce ghc.version;
              reinstallableLibGhc = true;
              packages.ghc.flags.ghci = pkgs.lib.mkForce true;
              packages.ghci.flags.ghci = pkgs.lib.mkForce true;
              # This fixes a performance issue, probably https://gitlab.haskell.org/ghc/ghc/issues/15524
              packages.haskell-language-server.configureFlags = [ "--enable-executable-dynamic" ];
              packages.haskell-lsp.components.library.doHaddock = pkgs.lib.mkForce false;
              packages.haskell-language-server.components.library.doHaddock = pkgs.lib.mkForce false;
            })];
          };
      mkHls = args@{...}:
        let packages = mkPackages ({ghc = pkgs.haskell-nix.compiler.ghc865; stackYaml = "stack.yaml"; } // args);
        in packages.haskell-language-server.components.exes.haskell-language-server // { inherit packages; };
    in { export = {
          hls-ghc864 = mkHls { ghc = pkgs.haskell-nix.compiler.ghc864; stackYaml = "stack-8.6.4.yaml"; };
          hls-ghc865 = mkHls { ghc = pkgs.haskell-nix.compiler.ghc865; stackYaml = "stack-8.6.5.yaml"; };
          hls-ghc882 = mkHls { ghc = pkgs.haskell-nix.compiler.ghc882; stackYaml = "stack-8.8.2.yaml"; };
          hls-ghc883 = mkHls { ghc = pkgs.haskell-nix.compiler.ghc883; stackYaml = "stack-8.8.3.yaml"; };
          hls-ghc8101 = mkHls { ghc = pkgs.haskell-nix.compiler.ghc8101; stackYaml = "stack-8.10.1.yaml"; };
          inherit mkHls;
         };

         devTools = {
           inherit (import sources.niv {}) niv;
         };
      };
in
import sources.nixpkgs {
  overlays = haskellnix.overlays ++ [ overlay ];
  config = haskellnix.config // {};
  inherit system;
}
