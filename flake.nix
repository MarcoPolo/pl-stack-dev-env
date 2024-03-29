# Notes:
# You'll want the direnv plugin in VSCode.
# If rust-analyzer fails to load in VSCode, try restarting the rust-analyzer server.
# the VSCode direnv plugin is a little racey. And it can load after the rust-analyzer starts.
{
  description = "PL dev environment";
  inputs.flake-utils.url = "github:numtide/flake-utils";
  inputs.rust-overlay.url = "github:oxalica/rust-overlay";
  inputs.nixpkgs.url = "github:nixos/nixpkgs/release-22.11";
  inputs.nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
  inputs.nixpkgs-darwin.url = "github:nixos/nixpkgs/nixpkgs-22.11-darwin";
  inputs.golang-flake.url = "github:marcopolo/golang-flake";

  outputs = inputs@{ self, nixpkgs, flake-utils, rust-overlay, ... }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        overlays = [ (import rust-overlay) ];
        os = builtins.elemAt (builtins.split "-" system) 2;
        pkgs = import (if os == "darwin" then inputs.nixpkgs-darwin else nixpkgs) { inherit system overlays; };
        pkgs-unstable = import inputs.nixpkgs-unstable {
          inherit system overlays;
        };
        rustStable = pkgs.rust-bin.stable.latest.default.override
          {
            extensions = [ "rust-src" ];
            targets = [ "wasm32-unknown-unknown" ];
          };
      in
      {
        devShell = pkgs.mkShell
          {
            buildInputs = [
              # Wasm
              pkgs.wasm-pack
              pkgs.wasm-bindgen-cli
              pkgs.binaryen

              pkgs.clang
              # pkgs.go_1_16
              # pkgs.go_1_17
              pkgs.pprof
              # For go 1.19
              pkgs.go_1_19
              pkgs.gopls
              rustStable

              # filecoin-ffi
              pkgs.rustup
              # If the project requires openssl, uncomment these
              pkgs.pkg-config
              pkgs.openssl
              pkgs.nodejs-18_x
              pkgs.yarn
              pkgs.ipfs
              # self.packages.${system}.go-car
              pkgs.hwloc
              # Fil markets
              pkgs.hwloc.dev
              pkgs.mockgen

              pkgs.awscli2

              # k8s
              pkgs.kustomize

              pkgs-unstable.terraform

              # plantuml
              pkgs.jdk11
              pkgs.plantuml

              pkgs.pandoc

              # Live markdown preview
              pkgs.python39Packages.grip

              # rust-libp2p uses prost which needs protobuf
              pkgs.protobuf

              # go-libp2p uses gogo protobuf
              self.packages.${system}.protoc-gen-gogofast
            ] ++ (if (system == "aarch64-darwin" || system == "x86_64-darwin") then [
              pkgs.darwin.apple_sdk.frameworks.OpenCL
              pkgs.darwin.apple_sdk.frameworks.CoreFoundation
              pkgs.darwin.apple_sdk.frameworks.CoreServices
              pkgs.darwin.apple_sdk.frameworks.Security
              pkgs.darwin.apple_sdk.frameworks.SystemConfiguration
            ] else [ ]);
            # If the project requires openssl, uncomment this
            PKG_CONFIG_PATH = "${pkgs.openssl.dev}/lib/pkgconfig";

            # For lotus to build
            # Otherwise we fetch binaries from github that are not build for macOS-arm
            FFI_BUILD_FROM_SOURCE = 1;
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

        packages.protoc-gen-gogofast = pkgs.buildGoModule
          rec {
            pname = "protoc-gen-gogofast";
            version = "1.3.2";

            src = pkgs.fetchFromGitHub {
              owner = "gogo";
              repo = "protobuf";
              rev = "v${version}";
              sha256 = "sha256-CoUqgLFnLNCS9OxKFS7XwjE17SlH6iL1Kgv+0uEK2zU=";
              # sha256 = pkgs.lib.fakeSha256;
            };

            vendorSha256 = "sha256-nOL2Ulo9VlOHAqJgZuHl7fGjz/WFAaWPdemplbQWcak=";
            # vendorSha256 = pkgs.lib.fakeSha256;

            subPackages = [ "protoc-gen-gogofast" "protoc-gen-gogofaster" ];
          };
      });
}
