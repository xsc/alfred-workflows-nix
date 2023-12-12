{ lib, pkgs, ... }:

let
  # Create Derivation for collected workflow
  mkAlfredWorkflow = { name, src, owner, version ? null }:
    let
      outPath = "share/alfred-workflows/${name}";
      workflowFile = "${outPath}/${name}.alfredworkflow";
      workflowDirectory = "${outPath}/workflow";
      activationScript = "${outPath}/activate";
    in
    pkgs.stdenvNoCC.mkDerivation {
      inherit name version;
      dontUnpack = true;
      dontConfigure = true;
      dontBuild = true;

      buildInputs = with pkgs; [
        unzip
      ];

      ACTIVATE_SCRIPT = builtins.readFile ./activation-script.sh;

      installPhase = ''
        runHook preInstall
        mkdir -p $out/${workflowDirectory}

        # Unpack
        unzip ${src} -d $out/${workflowDirectory}

        # Installation Script
        printenv ACTIVATE_SCRIPT > $out/${activationScript}
        chmod +x $out/${activationScript}

        # File
        cp --reflink=auto ${src} $out/${workflowFile}
        runHook postInstall
      '';

      isAlfredWorkflow = true;

      meta = {
        inherit owner;
        downloadPage = "https://alfred.app/workflows/${owner}/${name}";
      };

      passthru = {
        inherit activationScript workflowFile workflowDirectory;
      };
    };

  # Github Release Handling
  fetchGithubRelease = { owner, repo, version, artifactName ? null, hash, ... }:
    let
      filename =
        if artifactName == null
        then "${repo}.alfredworkflow"
        else artifactName;
    in
    pkgs.fetchurl {
      inherit hash;
      url =
        "https://github.com/${owner}/${repo}/releases/download/${version}/${filename}";
    };

  # Collect and package
  toAttrset = workflowPackages:
    lib.listToAttrs
      (map (pkg: lib.nameValuePair pkg.name pkg) workflowPackages);

in
{
  inherit mkAlfredWorkflow fetchGithubRelease toAttrset;

  # alfredUtils package
  package = pkgs.stdenvNoCC.mkDerivation {
    name = "alfredUtils";
    dontUnpack = true;
    dontConfigure = true;
    dontBuild = true;
    dontInstall = true;

    passthru = {
      inherit
        fetchGithubRelease
        mkAlfredWorkflow;
    };
  };
}
