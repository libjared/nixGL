{
  description = ''NixGL solve the "OpenGL" problem with nix'';
  inputs = {
    flake-utils.url = "github:numtide/flake-utils/master";
    nixpkgs.url = "github:nixos/nixpkgs/haskell-updates";
  };
  outputs = { self, nixpkgs, flake-utils }:
    with flake-utils.lib;
    eachSystem [ "x86_64-linux" ] (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          config = { allowUnfree = true; };
        };
      in rec {
        packages = flattenTree
          (with pkgs; recurseIntoAttrs ((import ./. { inherit pkgs; }).auto));
        defaultPackage = self.packages.${system}.nixGLDefault;
        nixosModules = rec {
          nixgl = import ./nixos;
          default = nixgl;
        };
      });
}
