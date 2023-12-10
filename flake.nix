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
      imports = [
        ./nix/darwin-modules.nix
      ];


      flake = {
        overlays = {
          alfred-gallery = final: prev:
            let utils = import ./nix/utils.nix prev;
            in {
              alfredGallery = self.packages.${prev.system};
              alfredUtils = utils.package;
            };
          default = self.overlays.alfred-gallery;
        };
      };

      systems = [ "aarch64-darwin" "x86_64-darwin" ];
      perSystem = { lib, pkgs, ... }:
        let
          utils =
            pkgs.callPackage ./nix/utils.nix { };
          availableWorkflows =
            pkgs.callPackage ./nix/available-workflows.nix { };
          workflowPackages = utils.collectAndPackage alfred-gallery;
        in
        {
          packages = utils.toAttrset workflowPackages;
          apps.default = availableWorkflows.mkApp workflowPackages;
        };
    };
}

