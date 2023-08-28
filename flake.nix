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
            nativeBuildInputs = with pkgs; [ nodejs ];
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

          gimlet-bin = pkgs.stdenv.mkDerivation rec {
            pname = "gimlet";
            version = "0.23.4";

            src =
              let
                selectSystem = attrs: attrs.${system} or (throw "Unsupported system: ${system}");

                suffix = selectSystem {
                  x86_64-linux = "linux-x86_64 ";
                  x86_64-darwin = "darwin-x86_64 ";
                  aarch64-linux = "linux-arm64";
                  aarch64-darwin = "darwin-arm64";
                };
                sha256 = selectSystem {
                  x86_64-linux = "sha256-6ysJuvYMpQ1uaZVc+7ZXPjEL6AxUe6oOmAFov5MGZCs=";
                  x86_64-darwin = "sha256-XiAqdozec7yK/Yt+Xwb89QsVqJrsqp+7cXCpPzg06GM=";
                  aarch64-linux = "sha256-H5VBpllJzaOiqsITejjWubriJ2Z2Lpouo8IMGkkLat4=";
                  aarch64-darwin = "sha256-A7LP/FTYxCWqZ7xlLhbjr24OzCTLFjvo7uf6ylm6edw=";
                };
              in
              pkgs.fetchurl {
                inherit sha256;

                url = "https://github.com/gimlet-io/gimlet/releases/download/cli-v${version}/gimlet-${suffix}";
              };

            dontUnpack = true;
            dontCheck = true;
            dontConfigure = true;
            dontBuild = true;

            installPhase = ''
              mkdir -p $out/bin
              cp $src $out/bin/gimlet
              chmod +x $out/bin/gimlet
            '';
          };
        };
      };
    };
}
