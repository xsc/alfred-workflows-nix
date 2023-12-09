{ lib, pkgs, ... }@inputs:

let utils = import ./utils.nix inputs; in
{
  generate = path: map utils.mkWorkflow (utils.collectWorkflows path);
}
