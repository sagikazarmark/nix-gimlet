# Nix flake for [Gimlet](https://gimlet.io/)

[![GitHub Workflow Status](https://img.shields.io/github/actions/workflow/status/sagikazarmark/nix-gimlet/ci.yaml?style=flat-square)](https://github.com/sagikazarmark/nix-gimlet/actions/workflows/ci.yaml)
[![built with nix](https://img.shields.io/badge/builtwith-nix-7d81f7?style=flat-square)](https://builtwithnix.org)

This is a flake for installing Gimlet CLI.

## Usage

```nix
{
  description = "Your flake";

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    gimlet.url = "github:sagikazarmark/nix-gimlet";
  };

  outputs = { self, nixpkgs, flake-utils, gimlet, ... }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
      in {
        devShell = pkgs.mkShell {
          buildInputs = [ gimlet.packages.${system}.gimlet ];
        };
      });
}
```

## License

The project is licensed under the [MIT License](LICENSE).
