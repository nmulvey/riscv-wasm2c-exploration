{
  # Anchor the project root at flake.nix so treefmt walks the whole tree.
  projectRootFile = "flake.nix";

  programs.nixfmt.enable = true;
  programs.clang-format.enable = true;

  settings.global.excludes = [
    # File types we don't have a sensible formatter for. Listing them
    # explicitly keeps `treefmt --fail-on-unmatched` honest.
    "*.S"
    "*.ld"
    "*.wat"
    "*.txt"
    "*.patch"
    "Makefile"
    "flake.lock"
    ".gitignore"
    ".clang-format"

    # Files that we vendor and don't want formatted:
    "tests/05_box/tweetnacl.c"
    "tests/05_box/tweetnacl.h"
    # PolyBenchC submodule + the near-verbatim copies kept upstream-faithful:
    "tests/06_polybench/PolyBenchC-4.2.1/**"
    "tests/06_polybench/atax.h"
  ];
}
