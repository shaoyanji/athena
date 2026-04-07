{ pkgs }:
let
  registryTypes = import ./registry/types.nix;
  baseRegistry = import ./registry/base.nix;
  registryOverlay = import ./registry/overlay.nix;
  startupViews = import ./registry/startup-views.nix;
  baseTaskfiles = import ./taskfiles/base.nix;
in
{
  identity = {
    name = "workspace-athena";
    kind = "workspace-seed";
  };

  registry = {
    types = registryTypes;
    base = baseRegistry;
    overlay = registryOverlay;
    startupViews = startupViews;
  };

  taskfiles = {
    base = baseTaskfiles;
  };
}
