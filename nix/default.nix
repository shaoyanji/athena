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

  profiles = [
    {
      name = "athena";
      description = "Base Athena operator/control-plane profile";
      default = true;
      shell = "athena";
      profileSource = ./../src;
      defaultWorkspaceRoot = "/var/lib/nullclaw/workspace";
      docFiles = [ "AGENTS.md" "SOUL.md" "USER.md" "ATHENA.md" ];
      packages = [
        "workspace-athena"
        "athena-activate"
        "athena-profile-manifest"
        "nixfmt-rfc-style"
        "statix"
        "deadnix"
        "yq-go"
      ];
      tools = [
        "git"
        "jq"
        "task"
        "yq"
        "nixfmt"
        "statix"
        "deadnix"
        "athena-activate"
      ];
      skills = [
        "registry-authoring"
        "workspace-materialization"
      ];
      startupViews = [ "bootstrap" ];
    }
    {
      name = "hermes";
      description = "Hermes agent — portable, on-demand AI system process";
      default = false;
      shell = "hermes";
      profileSource = ./../src/hermes;
      defaultWorkspaceRoot = "/var/lib/hermes/workspace";
      docFiles = [ "AGENTS.md" "SOUL.md" "HERMES.md" "ENV.md" ];
      packages = [
        "workspace-hermes"
        "hermes-activate"
        "hermes-profile-manifest"
      ];
      tools = [
        "git"
        "jq"
        "task"
      ];
      skills = [
        "workspace-materialization"
        "skill-import"
      ];
      startupViews = [ "bootstrap" "workspace-check" ];
    }
  ];

  packages = [
    {
      name = "workspace-athena";
      description = "Store output containing Athena live docs and registry projections";
      output = "workspace-athena";
      kind = "projection";
    }
    {
      name = "athena-activate";
      description = "Store-backed live workspace materialization command";
      output = "athena-activate";
      kind = "activation";
    }
    {
      name = "athena-profile-manifest";
      description = "Manifest projection of Athena profiles, packages, tools, and skills";
      output = "athena-profile-manifest";
      kind = "manifest";
    }
    {
      name = "nixfmt-rfc-style";
      description = "Nix formatter used in the Athena dev shell";
      output = "nixfmt-rfc-style";
      kind = "cli-support";
    }
    {
      name = "statix";
      description = "Nix linter used in the Athena dev shell";
      output = "statix";
      kind = "cli-support";
    }
    {
      name = "deadnix";
      description = "Dead code checker used in the Athena dev shell";
      output = "deadnix";
      kind = "cli-support";
    }
    {
      name = "yq-go";
      description = "YAML processor used for safe config editing";
      output = "yq-go";
      kind = "cli-support";
    }
  ];

  tools = [
    {
      name = "git";
      description = "Version control and repo transport";
      kind = "cli";
      package = "git";
    }
    {
      name = "jq";
      description = "JSON querying for checks and registry inspection";
      kind = "cli";
      package = "jq";
    }
    {
      name = "task";
      description = "Task runner for repo entrypoints";
      kind = "cli";
      package = "go-task";
    }
    {
      name = "yq";
      description = "YAML querying/editing for safe config maintenance";
      kind = "cli";
      package = "yq-go";
    }
    {
      name = "nixfmt";
      description = "Nix formatter";
      kind = "cli";
      package = "nixfmt-rfc-style";
    }
    {
      name = "statix";
      description = "Nix linter";
      kind = "cli";
      package = "statix";
    }
    {
      name = "deadnix";
      description = "Unused Nix code checker";
      kind = "cli";
      package = "deadnix";
    }
    {
      name = "athena-activate";
      description = "Live workspace materialization entrypoint";
      kind = "athena-command";
      package = "athena-activate";
    }
  ];

  skills = [
    {
      name = "registry-authoring";
      description = "Maintain Athena-authored registry truth and projections";
      portability = "portable";
      status = "real";
    }
    {
      name = "workspace-materialization";
      description = "Materialize the Athena live control surface into the workspace root";
      portability = "portable";
      status = "real";
    }
  ];

  effectiveRegistry = import ./registry/effective.nix {
    inherit identity;
    base = baseRegistry;
    inherit startupViews profiles packages tools skills;
  };

  baseTaskfiles = import ./taskfiles/base.nix;
in
{
  inherit identity profiles packages tools skills;

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
