{ pkgs }:
let
  registryTypes = import ./registry/types.nix;
  baseRegistry = import ./registry/base.nix;
  registryOverlay = import ./registry/overlay.nix;
  startupViews = import ./registry/startup-views.nix;
  identity = {
    name = "workspace-athena";
    kind = "workspace-seed";
  };
  effectiveRegistry = import ./registry/effective.nix {
    inherit identity;
    base = baseRegistry;
    inherit startupViews;
  };
  baseTaskfiles = import ./taskfiles/base.nix;
in
{
  inherit identity;

  registry = {
    types = registryTypes;
    base = baseRegistry;
    overlay = registryOverlay;
    startupViews = startupViews;
    effective = effectiveRegistry;
  };

  taskfiles = {
    base = baseTaskfiles;
  };
}
