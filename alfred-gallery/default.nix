{ alfred-gallery, lib, pkgs, utils, ... }:
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

  # Bring it together
  collectAndPackage = rootPath:
    map utils.mkAlfredWorkflow (collectWorkflows "${rootPath}");
in
collectAndPackage alfred-gallery
