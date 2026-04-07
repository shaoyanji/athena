[
  {
    name = "athena-core";
    source = "./src";
    startupView = true;
    kind = "docs";
  }
  {
    name = "athena-profile";
    source = "./flake.nix#athena";
    startupView = false;
    kind = "profile";
  }
  {
    name = "athena-activate";
    source = "./flake.nix#packages.<system>.athena-activate";
    startupView = false;
    kind = "package";
  }
  {
    name = "effective-registry";
    source = "./registry/effective/registry.json";
    startupView = true;
    kind = "registry";
  }
]
