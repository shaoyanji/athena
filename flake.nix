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
          lib = nixpkgs.lib;
          effectiveRegistryJson = builtins.toJSON athena.registry.effective;

          # Build workspace-{name} for each profile
          profileWorkspaces = lib.listToAttrs (map (profile:
            let
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
                profile = profile.name;
                registry = athena.registry.startupViews;
                effectiveRegistry = "share/${profile.name}/effective/registry.json";
                profileManifest = "share/${profile.name}/effective/profile-manifest.json";
                taskfiles = athena.taskfiles;
                notes = "Workspace seed only. Canonical task and registry logic lives in Nix.";
              };
              docInstallCmds = builtins.concatStringsSep "\n" (map (docFile:
                ''install -D -m 0644 ${profile.profileSource}/${docFile} "$out/share/${profile.name}/live/${docFile}"''
              ) profile.docFiles);
            in {
              name = "workspace-${profile.name}";
              value = pkgs.runCommand "workspace-${profile.name}" { } ''
                mkdir -p "$out/share/${profile.name}/effective" "$out/share/${profile.name}/live"
                cat > "$out/share/${profile.name}/seed.json" <<'EOF'
                ${seedJson}
                EOF
                cat > "$out/share/${profile.name}/effective/registry.json" <<'EOF'
                ${effectiveRegistryJson}
                EOF
                cat > "$out/share/${profile.name}/effective/profile-manifest.json" <<'EOF'
                ${profileManifestJson}
                EOF
                ${docInstallCmds}
              '';
            }
          ) athena.profiles);

          # Build {name}-activate for each profile
          profileActivations = lib.listToAttrs (map (profile:
            let
              workspacePkg = profileWorkspaces."workspace-${profile.name}";
              docSymlinkCmds = builtins.concatStringsSep "\n" (map (docFile:
                ''link_file_with_backup "$store_out/share/${profile.name}/live/${docFile}" "${docFile}"''
              ) profile.docFiles);
              docListCmds = builtins.concatStringsSep "\n              " (map (docFile:
                ''"$target/${docFile}" \\''
              ) profile.docFiles);
            in {
              name = "${profile.name}-activate";
              value = pkgs.writeShellScriptBin "${profile.name}-activate" ''
                set -euo pipefail

                mode_or_target="''${1:-workspace}"
                workspace_root="${profile.defaultWorkspaceRoot}"
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
                store_out="${workspacePkg}"

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

                link_file_with_backup "$store_out/share/${profile.name}/seed.json" "seed.json"
                link_file_with_backup "$store_out/share/${profile.name}/effective/registry.json" "registry/effective/registry.json"
                link_file_with_backup "$store_out/share/${profile.name}/effective/profile-manifest.json" "registry/effective/profile-manifest.json"
                ${docSymlinkCmds}

                echo "Symlink targets:"
                ls -l \
                  ${docListCmds}
                  "$target/seed.json" \
                  "$target/registry/effective/registry.json" \
                  "$target/registry/effective/profile-manifest.json"

                if [ -d "$backup_root" ]; then
                  echo "Activated ${profile.name} into $target (backup: $backup_root)"
                else
                  echo "Activated ${profile.name} into $target (no prior files needed backup)"
                fi
              '';
            }
          ) athena.profiles);

          # Build {name}-profile-manifest for each profile
          profileManifests = lib.listToAttrs (map (profile:
            let
              workspacePkg = profileWorkspaces."workspace-${profile.name}";
            in {
              name = "${profile.name}-profile-manifest";
              value = pkgs.runCommand "${profile.name}-profile-manifest" { } ''
                mkdir -p "$out/share/${profile.name}/effective"
                cp "${workspacePkg}/share/${profile.name}/effective/profile-manifest.json" "$out/share/${profile.name}/effective/profile-manifest.json"
              '';
            }
          ) athena.profiles);

          # Common runtime packages
          baseRuntime = {
            nixfmt-rfc-style = pkgs.nixfmt-rfc-style;
            statix = pkgs.statix;
            deadnix = pkgs.deadnix;
            yq-go = pkgs.yq-go;
            git = pkgs.git;
            jq = pkgs.jq;
            go-task = pkgs.go-task;
            python3 = pkgs.python3;
            go = pkgs.go;
            ripgrep = pkgs.ripgrep;
            curl = pkgs.curl;
            age = pkgs.age;
            sops = pkgs.sops;
          };

          # Merge profile-generated packages
          allProfilePackages = profileWorkspaces // profileActivations // profileManifests;

          default = self.packages.${system}.workspace-athena;
        in
        allProfilePackages // baseRuntime // { inherit default; }
      );

      checks = forAllSystems (system:
        let
          pkgs = import nixpkgs { inherit system; };
          athena = import ./nix/default.nix { inherit pkgs; };
          lib = nixpkgs.lib;

          # Registry contract check per profile
          profileChecks = lib.listToAttrs (map (profile:
            let
              workspacePkg = self.packages.${system}."workspace-${profile.name}";
            in {
              name = "${profile.name}-registry-contract";
              value = pkgs.runCommand "${profile.name}-registry-contract-check" { } ''
                registry="${workspacePkg}/share/${profile.name}/effective/registry.json"
                manifest="${workspacePkg}/share/${profile.name}/effective/profile-manifest.json"

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

                # Verify profile-specific docs exist
                ${builtins.concatStringsSep "\n" (map (docFile:
                  ''test -f "${workspacePkg}/share/${profile.name}/live/${docFile}"''
                ) profile.docFiles)}

                touch "$out"
              '';
            }
          ) athena.profiles);
        in
        profileChecks
      );

      devShells = forAllSystems (system:
        let
          pkgs = import nixpkgs { inherit system; };
          athena = import ./nix/default.nix { inherit pkgs; };
          lib = nixpkgs.lib;

          # Build a devShell for each profile
          profileShells = lib.listToAttrs (map (profile:
            let
              packageByName = builtins.listToAttrs (map (p: {
                name = p.name;
                value = p;
              }) athena.packages);
              toolByName = builtins.listToAttrs (map (t: {
                name = t.name;
                value = t;
              }) athena.tools);

              # Add profile-specific packages to the runtime map
              profileRuntime = {
                "workspace-${profile.name}" = self.packages.${system}."workspace-${profile.name}";
                "${profile.name}-activate" = self.packages.${system}."${profile.name}-activate";
                "${profile.name}-profile-manifest" = self.packages.${system}."${profile.name}-profile-manifest";
              };

              baseRuntime = {
                nixfmt-rfc-style = pkgs.nixfmt-rfc-style;
                statix = pkgs.statix;
                deadnix = pkgs.deadnix;
                yq-go = pkgs.yq-go;
                git = pkgs.git;
                jq = pkgs.jq;
                go-task = pkgs.go-task;
                python3 = pkgs.python3;
                go = pkgs.go;
                ripgrep = pkgs.ripgrep;
                curl = pkgs.curl;
                age = pkgs.age;
                sops = pkgs.sops;
              };

              allRuntime = baseRuntime // profileRuntime;

              resolvePackageName = name:
                if builtins.hasAttr name packageByName
                then allRuntime.${packageByName.${name}.output}
                else allRuntime.${name};
              resolveToolName = name:
                resolvePackageName toolByName.${name}.package;
              shellPackages = lib.unique (
                (map resolvePackageName profile.packages)
                ++ (map resolveToolName profile.tools)
              );
            in {
              name = profile.name;
              value = pkgs.mkShell {
                name = profile.name;
                packages = shellPackages;
                shellHook = ''
                  echo "${profile.name} devshell ready. Run: ${profile.name}-activate"
                '';
              };
            }
          ) athena.profiles);

          defaultProfile = builtins.head (builtins.filter (p: p.default) athena.profiles);
        in
        profileShells // { default = profileShells.${defaultProfile.name}; }
      );
    };
}
