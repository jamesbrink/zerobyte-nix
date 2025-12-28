# Development shell for zerobyte
{ pkgs, system, shoutrrr, bun2nixPkgs }:

pkgs.mkShell {
  buildInputs = [
    # JavaScript runtime and package manager
    pkgs.bun
    pkgs.nodejs

    # Development tools
    pkgs.biome
    pkgs.typescript

    # bun2nix CLI for regenerating bun.nix
    bun2nixPkgs.bun2nix

    # External tools (for local testing)
    pkgs.restic
    pkgs.rclone
    shoutrrr

    # Database tools
    pkgs.sqlite

    # Utilities
    pkgs.git
    pkgs.curl
    pkgs.jq
  ];

  shellHook = ''
    echo "Zerobyte-nix development environment"
    echo "  bun:      $(bun --version)"
    echo "  node:     $(node --version)"
    echo "  restic:   $(restic version | head -1)"
    echo ""
    echo "Commands:"
    echo "  update-bun-nix    Regenerate bun.nix from upstream"
    echo "  nix flake update  Update all flake inputs"

    update-bun-nix() {
      echo "Fetching upstream zerobyte..."
      local tmpdir=$(mktemp -d)
      git clone --depth 1 https://github.com/nicotsx/zerobyte "$tmpdir" || return 1
      echo "Generating bun.nix..."
      (cd "$tmpdir" && bun2nix -o "$(pwd)/bun.nix") || return 1
      cp "$tmpdir/bun.nix" ./bun.nix
      rm -rf "$tmpdir"
      echo "Updated bun.nix from upstream"
      echo "Don't forget to commit: git add bun.nix && git commit -m 'chore: update bun.nix from upstream'"
    }
  '';
}
