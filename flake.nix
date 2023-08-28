{
  description = "A gitops based developer platform that gives you the best of open-source out of the box.";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    devenv.url = "github:cachix/devenv";
  };

  outputs = inputs@{ flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      imports = [
        inputs.devenv.flakeModule
      ];

      systems = [ "x86_64-linux" "x86_64-darwin" "aarch64-darwin" ];

      perSystem = { config, self', inputs', pkgs, system, ... }: rec {
        devenv.shells = {
          default = {
            packages = with pkgs; [ ] ++ [
              self'.packages.gimlet
            ];

            # https://github.com/cachix/devenv/issues/528#issuecomment-1556108767
            containers = pkgs.lib.mkForce { };
          };

          ci = devenv.shells.default;
        };

        packages = {
          gimlet = pkgs.buildGoModule rec {
            name = "gimlet";
            version = "0.23.4";

            src = pkgs.fetchFromGitHub {
              owner = "gimlet-io";
              repo = "${name}";
              rev = "cli-v${version}";
              sha256 = "sha256-kIcAyNGaow75z0dkzhAwJIv/4CE5zcPYlzSJMwNX1kw=";
            };

            vendorSha256 = "sha256-ywVQ/2o1DO3L9S26eY+9GyMETTsSMhJeeEqo5LlVQBg=";

            CGO_ENABLED = 0;

            doCheck = false;
            subPackages = [ "cmd/cli" ];

            ldflags = [
              "-s"
              "-w"
              "-extldflags \"-static\""
              "-X github.com/gimlet-io/gimlet-cli/pkg/version.Version=v${version}"
            ];

            # This is VERY ugly
            nativeBuildInputs = with pkgs; [ nodejs nodePackages.webpack ];
            preBuild = ''
              export HOME=$(mktemp -d)
              make build-cli-frontend build-stack-frontend
            '';

            postInstall = ''
              mv $out/bin/cli $out/bin/gimlet
            '';

            meta = with pkgs.lib; {
              description = "A gitops based developer platform that gives you the best of open-source out of the box.";
              homepage = "https://github.com/gimlet-io/gimlet";
              license = licenses.asl20;
              platforms = platforms.unix;
            };
          };
        };
      };
    };
}
