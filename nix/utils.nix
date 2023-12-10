{ lib, pkgs, ... }:

rec {
  # Helpers
  readDir = path: lib.attrNames (builtins.readDir path);
  isWorkflow = file: lib.hasSuffix ".alfredworkflow" file;

  # Workflow collection from a publisher's directory
  collectWorkflowsFromDirectory = rootPath: directory:
    let
      files = readDir "${rootPath}/workflows/${directory}";
      workflowFiles = lib.filter isWorkflow files;
    in
    map
      (file: {
        owner = "${directory}";
        name = lib.removeSuffix ".alfredworkflow" file;
        src = "${rootPath}/workflows/${directory}/${file}";
      })
      workflowFiles;

  # Workflow collection from the 'alfred-gallery' root path
  collectWorkflows = rootPath:
    let
      workflowDirectories = readDir "${rootPath}/workflows";
      results = lib.concatLists (
        map (collectWorkflowsFromDirectory rootPath) workflowDirectories
      );
      allWorkflowNamesAreUnique = lib.allUnique (map (file: file.name) results);
    in
    (
      # Ensure that all workflow names are unique. When that stops being
      # the case, we have to somehow include the workflow's owner
      # name in the package name.
      assert allWorkflowNamesAreUnique;
      results
    );

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

      ACTIVATE_SCRIPT = builtins.readFile ../sh/activation-script.sh;

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
  collectAndPackage = rootPath:
    map mkAlfredWorkflow (collectWorkflows "${rootPath}");

  toAttrset = workflowPackages:
    lib.listToAttrs
      (map (pkg: lib.nameValuePair pkg.name pkg) workflowPackages);

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
