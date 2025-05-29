{s}: 
{
  ghcidScript = s "dev" "ghcid --command 'cabal new-repl lib:pipewire-hs' --allow-eval --warnings";
  testScript = s "test" "cabal run test:pipewire-hs-tests";
  hoogleScript = s "hgl" "hoogle serve";
}
