{
  description = "Athena local-first workspace seed";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs }:
    let
      systems = [
        "x86_64-linux"
        "aarch64-linux"
      ];
      forAllSystems = nixpkgs.lib.genAttrs systems;
    in
    {
      packages = forAllSystems (system:
        let
          pkgs = import nixpkgs { inherit system; };
          athena = import ./nix/default.nix { inherit pkgs; };
          seedJson = builtins.toJSON {
            name = athena.identity.name;
            kind = athena.identity.kind;
            registry = athena.registry.startupViews;
            taskfiles = athena.taskfiles;
            notes = "Workspace seed only. Canonical task and registry logic lives in Nix.";
          };
        in
        {
          workspace-athena = pkgs.runCommand "workspace-athena" { } ''
            mkdir -p "$out/share/athena"
            cat > "$out/share/athena/seed.json" <<'EOF'
            ${seedJson}
            EOF
          '';

          default = self.packages.${system}.workspace-athena;
        });

      devShells = forAllSystems (system:
        let
          pkgs = import nixpkgs { inherit system; };
        in
        {
          default = pkgs.mkShell {
            name = "athena";
            packages = with pkgs; [
              nixfmt-rfc-style
              statix
              deadnix
              jq
              yq-go
              go-task
              git
            ];

            shellHook = ''
              echo "Athena devshell: workspace seed, not a system package."
            '';
          };
        });
    };
}
