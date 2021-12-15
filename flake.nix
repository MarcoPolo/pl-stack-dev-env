# Notes:
# You'll want the direnv plugin in VSCode.
# If rust-analyzer fails to load in VSCode, try restarting the rust-analyzer server.
# the VSCode direnv plugin is a little racey. And it can load after the rust-analyzer starts.
{
  description = "PL dev environment";
  inputs.flake-utils.url = "github:numtide/flake-utils";
  inputs.rust-overlay.url = "github:oxalica/rust-overlay";

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
            pkgs.go
            rustStable
            # If the project requires openssl, uncomment these
            # pkgs.pkg-config
            # pkgs.openssl
            pkgs.nodejs
            pkgs.yarn
            pkgs.ipfs
          ];
          # If the project requires openssl, uncomment this
          # PKG_CONFIG_PATH = "${pkgs.openssl.dev}/lib/pkgconfig";
        };

        # packages.go-car =
        #   pkgs.buildGoModule rec {
        #     pname = "go-car";
        #     version = "2.1.1";

        #     src = pkgs.fetchFromGithub {
        #       owner = "ipld";
        #       repo = "go-car";
        #       rev = "v${version}";
        #       sha256 = pkgs.lib.fakeSha256;
        #     };

        #     vendorSha256 = pkgs.lib.fakeSha256;

        #     # buildPhase = "
        #     #     GOOS=js GOARCH=wasm go build -o main.wasm
        #     #   ";
        #     # installPhase = "
        #     #     cp -r www $out
        #     #     cp main.wasm $out/main.wasm
        #     #   ";

        #     meta = with pkgs.lib;
        #       {
        #         description = "go-car";
        #         homepage = "https://github.com/ipld/go-car";
        #         license = licenses.mit;
        #         platforms = platforms.linux ++ platforms.darwin;
        #       };
        #   };
      });
}
