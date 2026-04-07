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
          profileManifestJson = builtins.toJSON {
            workspace = athena.identity;
            profiles = athena.profiles;
            packages = athena.packages;
            tools = athena.tools;
            skills = athena.skills;
          };
          seedJson = builtins.toJSON {
            name = athena.identity.name;
            kind = athena.identity.kind;
            registry = athena.registry.startupViews;
            effectiveRegistry = "share/athena/effective/registry.json";
            profileManifest = "share/athena/effective/profile-manifest.json";
            taskfiles = athena.taskfiles;
            notes = "Workspace seed only. Canonical task and registry logic lives in Nix.";
          };
        in
        rec {
          workspace-athena = pkgs.runCommand "workspace-athena" { } ''
            mkdir -p "$out/share/athena/effective" "$out/share/athena/live"
            cat > "$out/share/athena/seed.json" <<'EOF'
            ${seedJson}
            EOF
            cat > "$out/share/athena/effective/registry.json" <<'EOF'
            ${effectiveRegistryJson}
            EOF
            cat > "$out/share/athena/effective/profile-manifest.json" <<'EOF'
            ${profileManifestJson}
            EOF

            install -m 0644 ${./src/AGENTS.md} "$out/share/athena/live/AGENTS.md"
            install -m 0644 ${./src/SOUL.md} "$out/share/athena/live/SOUL.md"
            install -m 0644 ${./src/USER.md} "$out/share/athena/live/USER.md"
            install -m 0644 ${./src/athena.md} "$out/share/athena/live/ATHENA.md"
          '';

          athena-activate = pkgs.writeShellScriptBin "athena-activate" ''
            set -euo pipefail

            mode_or_target="''${1:-workspace}"
            workspace_root="/var/lib/nullclaw/workspace"
            target="$workspace_root"

            case "$mode_or_target" in
              workspace) ;;
              /*) target="$mode_or_target" ;;
              *)
                echo "Unsupported target '$mode_or_target'. Use: workspace | /absolute/path" >&2
                exit 2
                ;;
            esac

            ts="$(date +%Y%m%d-%H%M%S)"
            backup_root="$target/.athena-backup/$ts"
            store_out="${workspace-athena}"

            backup_if_exists() {
              local rel="$1"
              local p="$target/$rel"
              if [ -e "$p" ] || [ -L "$p" ]; then
                mkdir -p "$backup_root/$(dirname "$rel")"
                cp -a "$p" "$backup_root/$rel"
              fi
            }

            link_file_with_backup() {
              local src="$1"
              local rel="$2"
              backup_if_exists "$rel"
              mkdir -p "$target/$(dirname "$rel")"
              ln -sfn "$src" "$target/$rel"
            }

            link_file_with_backup "$store_out/share/athena/seed.json" "seed.json"
            link_file_with_backup "$store_out/share/athena/effective/registry.json" "registry/effective/registry.json"
            link_file_with_backup "$store_out/share/athena/effective/profile-manifest.json" "registry/effective/profile-manifest.json"
            link_file_with_backup "$store_out/share/athena/live/AGENTS.md" "AGENTS.md"
            link_file_with_backup "$store_out/share/athena/live/SOUL.md" "SOUL.md"
            link_file_with_backup "$store_out/share/athena/live/USER.md" "USER.md"
            link_file_with_backup "$store_out/share/athena/live/ATHENA.md" "ATHENA.md"

            echo "Symlink targets:"
            ls -l \
              "$target/AGENTS.md" \
              "$target/SOUL.md" \
              "$target/USER.md" \
              "$target/ATHENA.md" \
              "$target/seed.json" \
              "$target/registry/effective/registry.json" \
              "$target/registry/effective/profile-manifest.json"

            if [ -d "$backup_root" ]; then
              echo "Activated Athena into $target (backup: $backup_root)"
            else
              echo "Activated Athena into $target (no prior files needed backup)"
            fi
          '';

          athena-profile-manifest = pkgs.runCommand "athena-profile-manifest" { } ''
            mkdir -p "$out/share/athena/effective"
            cp "${workspace-athena}/share/athena/effective/profile-manifest.json" "$out/share/athena/effective/profile-manifest.json"
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
            manifest="${workspaceAthena}/share/athena/effective/profile-manifest.json"

            test -f "$registry"
            test "$(${pkgs.jq}/bin/jq -r '.workspace.name' "$registry")" = "workspace-athena"
            test "$(${pkgs.jq}/bin/jq -r '.registryVersion' "$registry")" = "1"
            test "$(${pkgs.jq}/bin/jq '.entries | length' "$registry")" -gt 0
            test "$(${pkgs.jq}/bin/jq '.startupViews | length' "$registry")" -gt 0
            test "$(${pkgs.jq}/bin/jq -r '.startupViews[0].name' "$registry")" = "bootstrap"
            test "$(${pkgs.jq}/bin/jq '.profiles | length' "$registry")" -gt 0
            test "$(${pkgs.jq}/bin/jq '.packages | length' "$registry")" -gt 0
            test "$(${pkgs.jq}/bin/jq '.tools | length' "$registry")" -gt 0
            test "$(${pkgs.jq}/bin/jq '.skills | length' "$registry")" -gt 0
            test "$(${pkgs.jq}/bin/jq -r '.profiles[0].name' "$registry")" = "athena"

            test -f "$manifest"
            test "$(${pkgs.jq}/bin/jq -r '.profiles[0].name' "$manifest")" = "athena"
            test "$(${pkgs.jq}/bin/jq '.packages | length' "$manifest")" -gt 0
            test "$(${pkgs.jq}/bin/jq '.tools | length' "$manifest")" -gt 0
            test "$(${pkgs.jq}/bin/jq '.skills | length' "$manifest")" -gt 0

            touch "$out"
          '';
        });

      devShells = forAllSystems (system:
        let
          pkgs = import nixpkgs { inherit system; };
          athena = import ./nix/default.nix { inherit pkgs; };
          lib = nixpkgs.lib;
          profile = builtins.head (builtins.filter (p: p.name == "athena") athena.profiles);
          packageByName = builtins.listToAttrs (map (p: {
            name = p.name;
            value = p;
          }) athena.packages);
          toolByName = builtins.listToAttrs (map (t: {
            name = t.name;
            value = t;
          }) athena.tools);
          packageRuntime = {
            workspace-athena = self.packages.${system}.workspace-athena;
            athena-activate = self.packages.${system}.athena-activate;
            athena-profile-manifest = self.packages.${system}.athena-profile-manifest;
            nixfmt-rfc-style = pkgs.nixfmt-rfc-style;
            statix = pkgs.statix;
            deadnix = pkgs.deadnix;
            yq-go = pkgs.yq-go;
            git = pkgs.git;
            jq = pkgs.jq;
            go-task = pkgs.go-task;
          };
          resolvePackageName = name:
            if builtins.hasAttr name packageByName
            then packageRuntime.${packageByName.${name}.output}
            else packageRuntime.${name};
          resolveToolName = name:
            resolvePackageName toolByName.${name}.package;
          shellPackages = lib.unique (
            (map resolvePackageName profile.packages)
            ++ (map resolveToolName profile.tools)
          );
        in
        rec {
          athena = pkgs.mkShell {
            name = "athena";
            packages = shellPackages;

            shellHook = ''
              echo "Athena devshell ready. Run: athena-activate"
            '';
          };

          default = athena;
        });
    };
}
