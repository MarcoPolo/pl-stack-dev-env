# Notes:
# You'll want the direnv plugin in VSCode.
# If rust-analyzer fails to load in VSCode, try restarting the rust-analyzer server.
# the VSCode direnv plugin is a little racey. And it can load after the rust-analyzer starts.
{
  description = "PL dev environment";
  inputs.flake-utils.url = "github:numtide/flake-utils";
  inputs.rust-overlay.url = "github:oxalica/rust-overlay";
  inputs.nixpkgs.url = "github:nixos/nixpkgs/release-21.11";

  outputs = { self, nixpkgs, flake-utils, rust-overlay }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        overlays = [ (import rust-overlay) ];
        pkgs = import nixpkgs { inherit system overlays; };
        rustStable = pkgs.rust-bin.stable.latest.default.override {
          extensions = [ "rust-src" ];
        };
      in
      {
        devShell = pkgs.mkShell {
          buildInputs = [
            pkgs.go_1_17
            rustStable
            # If the project requires openssl, uncomment these
            # pkgs.pkg-config
            # pkgs.openssl
            pkgs.nodejs
            pkgs.yarn
            pkgs.ipfs
            self.packages.${system}.go-car
            pkgs.hwloc
            pkgs.mockgen

            # rust-libp2p uses prost which needs protobuf
            pkgs.protobuf
          ] ++ (if (system == "aarch64-darwin" || system == "x86_64-darwin") then [
            pkgs.darwin.apple_sdk.frameworks.OpenCL
            pkgs.darwin.apple_sdk.frameworks.CoreFoundation
            pkgs.darwin.apple_sdk.frameworks.Security
          ] else [ ]);
          # If the project requires openssl, uncomment this
          # PKG_CONFIG_PATH = "${pkgs.openssl.dev}/lib/pkgconfig";

          # For lotus to build
          # FFI_BUILD_FROM_SOURCE = 1;
        };

        packages.go-car =
          pkgs.buildGoModule rec {
            pname = "go-car";
            version = "2.1.1";

            src = pkgs.fetchFromGitHub
              {
                owner = "ipld";
                repo = "go-car";
                rev = "v${version}";
                sha256 = "sha256-fC/+MjujbUunU7pOTMZU097hqSLmfDBAflXWFZBBQks=";
              } + /cmd;

            vendorSha256 = "sha256-OITJ5NqnaO+deDYa12L51xET6Gr/aDoYhojZVjzQuP8=";
          };
      });
}
