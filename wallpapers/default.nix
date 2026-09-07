# Builds { ultrawide = { <name> = drv; ... }; widescreen = { ... }; } from
# list.json. Every derivation is a fetchurl of a PNG attached to a GitHub
# release of this repository (see scripts/release.sh).
{pkgs}: let
  inherit (pkgs) lib;

  variants = {
    ultrawide = {
      resolution = "5120x2160";
      aspect = "21:9";
    };
    widescreen = {
      resolution = "3840x2160";
      aspect = "16:9";
    };
  };

  entries = lib.importJSON ./list.json;

  mkWallpaper = variant: entry: let
    inherit (variants.${variant}) resolution aspect;
    file = "${entry.name}-${resolution}.png";
  in
    pkgs.fetchurl {
      name = file;
      inherit (entry.variants.${variant}) url hash;
      meta = {
        description = "${entry.description} (${resolution}, ${aspect})";
        homepage = entry.source;
      };
      passthru = {
        inherit (entry) name description source;
        inherit variant resolution aspect;
      };
    };

  bySet = variant: _:
    lib.listToAttrs (map (entry: lib.nameValuePair entry.name (mkWallpaper variant entry)) entries);
in
  lib.mapAttrs bySet variants
