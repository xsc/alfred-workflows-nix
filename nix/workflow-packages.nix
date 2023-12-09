{ lib, pkgs, ... }:

let
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
        name = lib.removeSuffix ".alfredworkflow" file;
        path = "${rootPath}/workflows/${directory}/${file}";
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
      # the case, we have to somehow include the workflow's publisher
      # name in the package name.
      assert allWorkflowNamesAreUnique;
      results
    );

  # Create Derivation for collected workflow
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

        ACTIVATE_SCRIPT = builtins.readFile ../sh/activation-script.sh;

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
in
{
  generate = path:
    lib.listToAttrs (
      map mkWorkflowPackage (collectWorkflows path)
    );
}
