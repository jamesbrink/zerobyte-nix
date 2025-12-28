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
    echo "Zerobyte development environment"
    echo "  bun:      $(bun --version)"
    echo "  node:     $(node --version)"
    echo "  restic:   $(restic version | head -1)"
    echo "  rclone:   $(rclone version | head -1)"
    echo ""
    echo "To update bun.nix after changing dependencies:"
    echo "  bun2nix -o bun.nix"
  '';
}
