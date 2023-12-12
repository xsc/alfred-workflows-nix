{ pkgs, lib, ... }:


let
  mkProgram = packages:
    let
      json =
        builtins.toJSON
          (map
            (pkg: {
              inherit (pkg) name;
              inherit (pkg.meta) downloadPage;
              fullName = "${pkg.meta.owner}/${pkg.name}";
            })
            packages);
      jsonFile = pkgs.writeText "available-workflows.json" json;
    in
    pkgs.writeScriptBin "available-packages" ''
      jq=${pkgs.jq}/bin/jq
      if [ "$1" = "--json" ]; then
        cat ${jsonFile} | $jq 'sort_by(.name)'
      else
        cat ${jsonFile} | $jq -r 'sort_by(.name) | .[].name'
      fi
    '';
in
{
  mkApp = packages:
    let program = mkProgram packages;
    in {
      type = "app";
      program = "${program}/bin/available-packages";
    };
}




