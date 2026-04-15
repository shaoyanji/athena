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
    name = "hermes-core";
    source = "./src/hermes";
    startupView = true;
    kind = "docs";
  }
  {
    name = "hermes-profile";
    source = "./flake.nix#hermes";
    startupView = false;
    kind = "profile";
  }
  {
    name = "hermes-activate";
    source = "./flake.nix#packages.<system>.hermes-activate";
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
