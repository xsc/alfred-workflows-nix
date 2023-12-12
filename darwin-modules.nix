{ self, ... }:
{
  flake.darwinModules = {
    # Module to include overlay
    includeOverlay = { config, pkgs, ... }: {
      nixpkgs.overlays = [ self.overlays.default ];
    };

    # Module to activate the workflows after installation
    activateWorkflows = { config, ... }:
      let
        pkgs = config.environment.systemPackages;
        alfredWorkflows = builtins.filter (pkg: pkg ? isAlfredWorkflow) pkgs;
      in
      {
        system.activationScripts.postUserActivation.text =
          builtins.concatStringsSep ";" (map (pkg: "${pkg}/${pkg.activationScript}") alfredWorkflows);
      };
  };
}
