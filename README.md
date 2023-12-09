# alfred-workflows-nix

Packages [alfredapp/gallery-workflows][repo] as flake outputs for easy access
in your Nix packages configuration.

[repo]: https://github.com/alfredapp/gallery-workflows

## Usage

Generally, this is how you'd use this flake:

1. Add it to your `inputs`.
2. [Apply the overlay][nixos-overlays].
3. (Optional) Include the activation module.

Here's an example that installs two Alfred workflows (but not Alfred itself):

```nix
{
  inputs = {
    nixpkgs.url = "github:dustinlyons/nixpkgs/master";
    darwin = {
      url = "github:LnL7/nix-darwin/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    alfred.url = "github:xsc/alfred-workflows-nix";
  };

  outputs = { self, nixpkgs, darwin, alfred, ... }: {
    darwinConfigurations.macos = darwin.lib.darwinSystem {
      system = "aarch64-darwin";
      modules = [
        ({ config, pkgs, ... }: {
          nixpkgs.overlays = [ alfred.overlays.default ];
          environment.systemPackages = with pkgs; [
            alfredGallery.spotify-mini-player
            alfredGallery.emoji-search
            unzip
          ];
        })
        alfred.darwinModules.activateWorkflows
      ];
    };
  };
}
```

[nixos-overlays]: https://nixos.wiki/wiki/Flakes#Importing_packages_from_multiple_channels

### Packages

Workflows will be available via `pkgs.alfredGallery`, with their name being the
same as the Alfred workflow ID. Examples include:

- [`spotify-mini-player`](https://alfred.app/workflows/vdesabou/spotify-mini-player/)
- [`alfred-gallery`](https://alfred.app/workflows/alfredapp/alfred-gallery/)
- [`1password`](https://alfred.app/workflows/alfredapp/1password/)

#### Activation

Every package comes with an activation script. The passthru option
`activationScript` points at the script, relative to the package directory,
which you can use however you see fit, e.g.:

```nix
system.activationScripts.postUserActivation.text = ''
  ${spotify-mini-player}/${spotify-mini-player.activationScript}
'';
```

The script will symlink the workflow files to the default Alfred workflow
directory at `~/Library/Application
Support/Alfred/Alfred.alfredpreferences/workflows`. It will preserve the
`info.plist` file if it exists, and in any case it will ensure that `info.plist`
is writeable (since you couldn't configure your workflows otherwise).

#### List available packages

You can generate a list of the available packages using one of:

```sh
nix run github:xsc/alfred-workflows-nix
nix run github:xsc/alfred-workflows-nix -- --json
```

### Modules

There are two modules contained in the flake (at `<flake>.darwinModules`):

- `includeOverlay` will add the overlay to `nixpkgs.overlays`.
- `activateWorkflows` will add a `postUserActivation` script to copy workflows to
  Alfred's workflow directory. It will automatically use any Alfred workflows
  in `environment.systemPackages`.


## License

```
MIT License

Copyright (c) 2023 Yannick Scherer

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```
