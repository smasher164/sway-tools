{
  description = "sway tools";
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    let supportedSystems = [
      "aarch64-linux"
      "i686-linux"
      "x86_64-linux"
    ]; in
    flake-utils.lib.eachSystem supportedSystems (system:
      let
        vscode-overlay = final: prev: {
          vscode = prev.vscode.overrideAttrs (old: {
            buildInputs = old.buildInputs or [ ] ++ [ final.makeWrapper ];
            postFixup = old.postFixup or "" + ''
              wrapProgram $out/bin/${pkgs.vscode.executableName} \
                --add-flags "--enable-features=UseOzonePlatform --ozone-platform=wayland"
            '';
          });
        };
        pkgs = import nixpkgs {
          inherit system;
          config.allowUnfree = true;
          overlays = [ vscode-overlay ];
        };
        vscode-with-extensions = pkgs.vscode-with-extensions.override {
          vscodeExtensions = [ pkgs.vscode-extensions.matklad.rust-analyzer ];
        };
      in
      {
        packages.pw-volume = pkgs.rustPlatform.buildRustPackage {
          name = "pw-volume";
          src = ./pw-volume/.;
          cargoLock.lockFile = ./pw-volume/Cargo.lock;
        };
        devShell = pkgs.mkShell {
          buildInputs = [
            pkgs.cargo
            pkgs.rustc
            pkgs.clippy
            pkgs.rustfmt
            vscode-with-extensions
          ];
        };
      });
}
