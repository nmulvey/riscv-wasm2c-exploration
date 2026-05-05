{
  # Anchor the project root at flake.nix so treefmt walks the whole tree.
  projectRootFile = "flake.nix";

  programs.nixfmt.enable = true;
  programs.clang-format.enable = true;

  # File types we don't have a sensible formatter for. Listing them
  # explicitly keeps `treefmt --fail-on-unmatched` honest.
  settings.global.excludes = [
    "*.S"
    "*.ld"
    "*.wat"
    "*.txt"
    "*.patch"
    "Makefile"
    "flake.lock"
    ".gitignore"
    ".clang-format"
  ];
}
