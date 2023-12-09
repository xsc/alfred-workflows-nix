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
        overlays.alfredGallery = final: prev: {
          alfredGallery = self.packages.${prev.system};
        };
        overlays.default = self.overlays.alfredGallery;
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
              target = "share/alfred-workflows/${name}.alfredworkflow";
            in
            lib.nameValuePair name (
              pkgs.stdenvNoCC.mkDerivation {
                inherit name;
                dontUnpack = true;
                dontConfigure = true;
                dontBuild = true;
                installPhase = ''
                  runHook preInstall
                  mkdir -p $out/share/alfred-workflows
                  cp --reflink=auto ${path} $out/${target}
                  runHook postInstall
                '';

                passthru = {
                  workflowFile = target;
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

