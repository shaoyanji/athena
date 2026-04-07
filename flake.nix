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
          effectiveRegistryJson = builtins.toJSON athena.registry.effective;
          seedJson = builtins.toJSON {
            name = athena.identity.name;
            kind = athena.identity.kind;
            registry = athena.registry.startupViews;
            effectiveRegistry = "share/athena/effective/registry.json";
            taskfiles = athena.taskfiles;
            notes = "Workspace seed only. Canonical task and registry logic lives in Nix.";
          };
        in
        {
          workspace-athena = pkgs.runCommand "workspace-athena" { } ''
            mkdir -p "$out/share/athena/effective"
            cat > "$out/share/athena/seed.json" <<'EOF'
            ${seedJson}
            EOF
            cat > "$out/share/athena/effective/registry.json" <<'EOF'
            ${effectiveRegistryJson}
            EOF
          '';

          default = self.packages.${system}.workspace-athena;
        });

      checks = forAllSystems (system:
        let
          pkgs = import nixpkgs { inherit system; };
          workspaceAthena = self.packages.${system}.workspace-athena;
        in
        {
          registry-contract = pkgs.runCommand "athena-registry-contract-check" { } ''
            registry="${workspaceAthena}/share/athena/effective/registry.json"

            test -f "$registry"
            test "$(${pkgs.jq}/bin/jq -r '.workspace.name' "$registry")" = "workspace-athena"
            test "$(${pkgs.jq}/bin/jq -r '.registryVersion' "$registry")" = "1"
            test "$(${pkgs.jq}/bin/jq '.entries | length' "$registry")" -gt 0

            touch "$out"
          '';
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
