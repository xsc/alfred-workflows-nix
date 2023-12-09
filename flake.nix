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
        #     ./nix/available-workflows.nix
      ];


      flake = {
        overlays = {
          alfred-gallery = final: prev: {
            alfredGallery = self.packages.${prev.system};
          };
          default = self.overlays.alfred-gallery;
        };
      };

      systems = [ "aarch64-darwin" "x86_64-darwin" ];
      perSystem = { lib, pkgs, ... }:
        let
          gen = pkgs.callPackage ./nix/generate-packages.nix { };
          availableWorkflows = pkgs.callPackage ./nix/available-workflows.nix { };
          workflowPackages = gen.generate "${alfred-gallery}";
        in
        {
          packages = lib.listToAttrs (
            map (pkg: lib.nameValuePair pkg.name pkg) workflowPackages
          );
          apps.default = availableWorkflows.mkApp workflowPackages;
        };
    };
}

