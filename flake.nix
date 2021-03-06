{
  description = "sway tools";
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    let supportedSystems = [
      "aarch64-linux"
      "x86_64-linux"
    ]; in
    flake-utils.lib.eachSystem supportedSystems (system:
      let
        vscode-overlay = final: prev: {
          vscodium = prev.vscodium.overrideAttrs (old: {
            buildInputs = old.buildInputs or [ ] ++ [ final.makeWrapper ];
            postFixup = old.postFixup or "" + ''
              wrapProgram $out/bin/${pkgs.vscodium.executableName} \
                --add-flags "--enable-features=UseOzonePlatform --ozone-platform=wayland"
            '';
          });
        };
        pkgs = import nixpkgs {
          inherit system;
          overlays = [ vscode-overlay ];
        };
        vscode-with-extensions = pkgs.vscode-with-extensions.override {
          vscode = pkgs.vscodium;
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
          shellHook = ''
            function release() {
              if [ "$#" -ne 1 ] || ([ $1 != "x86_64-musl" ] && [ $1 != "aarch64-musl" ]); then
                echo "Usage: release [ x86_64-musl | aarch64-musl ]"
                return 1
              fi
              sudo docker run --rm -it -v $PWD:/home/rust/src messense/rust-musl-cross:$1 cargo build --release
            }
          '';
        };
      });
}
