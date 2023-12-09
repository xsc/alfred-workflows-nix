{
  description = "Overlay exporing 'alfredapp/gallery-workflows' for easy usage in Nix";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    alfred-gallery = {
      url = "github:alfredapp/gallery-workflows";
      flake = false;
    };
  };

  outputs = { self, nixpkgs, flake-parts, alfred-gallery }@inputs:
    flake-parts.lib.mkFlake { inherit inputs; } {
      imports = [ ];

      flake = {
        # Overlay
        overlays.alfred-gallery = final: prev: {
          alfredGallery = self.packages.${prev.system};
        };
        overlays.default = self.overlays.alfred-gallery;

        # Module to include overlay
        modules.includeOverlay = { config, pkgs, ... }: {
          nixpkgs.overlays = [ self.overlays.default ];
        };

        # Module to activate the workflows after installation
        modules.activateWorkflows = { config, ... }:
          let
            pkgs = config.environment.systemPackages;
            alfredWorkflows = builtins.filter (pkg: pkg ? isAlfredWorkflow) pkgs;
          in
          {
            system.activationScripts.postUserActivation.text =
              builtins.concatStringsSep ";" (map (pkg: "${pkg}/${pkg.activationScript}") alfredWorkflows);
          };
      };

      systems = [ "aarch64-darwin" "x86_64-darwin" ];
      perSystem = { lib, pkgs, ... }:
        let
          # Helpers
          readDir = path: lib.attrNames (builtins.readDir path);
          isWorkflow = file: lib.hasSuffix ".alfredworkflow" file;
          collectWorkflows = directory:
            let
              files = readDir "${alfred-gallery}/workflows/${directory}";
              workflowFiles = lib.filter isWorkflow files;
            in
            map
              (file: rec {
                name = lib.removeSuffix ".alfredworkflow" file;
                path = "${alfred-gallery}/workflows/${directory}/${file}";
              })
              workflowFiles;

          # Collect Workflow Files
          workflowDirectories = readDir "${alfred-gallery}/workflows";
          workflowFiles =
            let
              results = lib.concatLists (map collectWorkflows workflowDirectories);
              allWorkflowNamesAreUnique = lib.allUnique (map (file: file.name) results);
            in
            (
              # Ensure that all workflow names are unique. When that stops being
              # the case, we have to somehow include the workflow's publisher
              # name in the package name.
              assert allWorkflowNamesAreUnique;
              results
            );

          # Create Packages
          mkWorkflowPackage = { name, path, ... }:
            let
              outPath = "share/alfred-workflows/${name}";
              workflowFile = "${outPath}/${name}.alfredworkflow";
              workflowDirectory = "${outPath}/workflow";
              activationScript = "${outPath}/activate";
            in
            lib.nameValuePair name (
              pkgs.stdenvNoCC.mkDerivation {
                inherit name;
                dontUnpack = true;
                dontConfigure = true;
                dontBuild = true;

                buildInputs = with pkgs; [
                  unzip
                ];

                ACTIVATE_SCRIPT = ''
                  #!/bin/sh
                  WORKDIR=$(readlink -f $(dirname "$0"))
                  TARGET_DIR="$HOME/Library/Application Support/Alfred/Alfred.alfredpreferences/workflows/${name}"

                  mkdir -p "$TARGET_DIR"

                  # Backup settings
                  if [ -f "$TARGET_DIR/info.plist" ]; then
                    mv -f "$TARGET_DIR/info.plist" "$TARGET_DIR/info.plist.backup"
                  fi

                  # Symlink workflow
                  ln -sf $WORKDIR/workflow/* "$TARGET_DIR"

                  # Restore backed up settings
                  # OR Replace the symlinked settings with a mutable file
                  if [ -f "$TARGET_DIR/info.plist.backup" ]; then
                    mv -f "$TARGET_DIR/info.plist.backup" "$TARGET_DIR/info.plist"
                  else
                    rm "$TARGET_DIR/info.plist"
                    cp -fL $WORKDIR/workflow/info.plist "$TARGET_DIR"
                  fi
                '';

                installPhase = ''
                  runHook preInstall
                  mkdir -p $out/${workflowDirectory}

                  # Unpack
                  unzip ${path} -d $out/${workflowDirectory}

                  # Installation Script
                  printenv ACTIVATE_SCRIPT > $out/${activationScript}
                  chmod +x $out/${activationScript}

                  # File
                  cp --reflink=auto ${path} $out/${workflowFile}
                  runHook postInstall
                '';

                isAlfredWorkflow = true;

                passthru = {
                  inherit activationScript workflowFile workflowDirectory;
                };
              });
          workflowDerivations = map mkWorkflowPackage workflowFiles;
        in
        {
          packages =
            lib.listToAttrs workflowDerivations;
        };
    };
}

