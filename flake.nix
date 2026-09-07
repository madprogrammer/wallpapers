{
  description = "Dark ultrawide (5K2K) wallpapers with 4K UHD crops, packaged for Nix";

  inputs.nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

  outputs = {nixpkgs, ...}: let
    inherit (nixpkgs) lib;
    forEachSystem = lib.genAttrs lib.systems.flakeExposed;
    wallpapersFor = system: import ./wallpapers {pkgs = nixpkgs.legacyPackages.${system};};
  in {
    # Nested sets, one per aspect ratio, keyed by wallpaper name:
    #   ultrawide.<name>   5120x2160 (21:9, 5K2K)
    #   widescreen.<name>  3840x2160 (16:9, 4K UHD)
    legacyPackages = forEachSystem wallpapersFor;

    # Flat derivations for `nix build .#<name>-<WxH>`, plus `all` (a link farm
    # of every variant) as the default package.
    packages = forEachSystem (system: let
      pkgs = nixpkgs.legacyPackages.${system};
      wallpapers = wallpapersFor system;
      flat = lib.listToAttrs (lib.concatMap (set:
        map (drv: lib.nameValuePair drv.name drv) (lib.attrValues set)) (lib.attrValues wallpapers));
      all = pkgs.linkFarmFromDrvs "wallpapers" (lib.attrValues flat);
    in
      flat // {inherit all; default = all;});

    formatter = forEachSystem (system: nixpkgs.legacyPackages.${system}.alejandra);
  };
}
