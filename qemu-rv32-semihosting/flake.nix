{
  description = "Bare-metal rv32 hello-world for QEMU `virt` with semihosting.";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
      treefmt-nix,
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs { inherit system; };
        inherit (pkgs) lib;

        treefmtEval = treefmt-nix.lib.evalModule pkgs ./treefmt.nix;

        # Build all of our targets for this particular RISC-V architecture.
        targetMarch = "rv32imac";
        targetMabi = "ilp32";

        # Using `crossSystem` forces a rebuild of the entire compiler toolchain
        # (stage 0 and stage 1). We instead build just newlib with our correct
        # target spec, and override the compiler flags in the Makefile:
        #
        # crossFor = forAllSystems (system: import nixpkgs {
        #   inherit system;
        #   crossSystem = {
        #     config = "riscv32-none-elf";
        #     libc = "newlib";
        #     gcc = {
        #       arch = targetMarch;
        #       abi  = targetMabi;
        #     };
        #   };
        # });

        # Use the Nix prebuilt stdenv, then override newlib:
        crossPkgs = pkgs.pkgsCross.riscv32-embedded;

        targetNewlib = crossPkgs.newlib.overrideAttrs (_old: {
          CFLAGS_FOR_TARGET = "-O2 -march=rv32imac -mabi=ilp32 -mcmodel=medany";
        });

        patchedWabt = pkgs.wabt.overrideAttrs (oldAttrs: {
          patches = [ ./0001-wasm2c-wasm-rt-allow-overriding-WASM_RT_THREAD_LOCAL.patch ];
        });

        # Enumerate test directories (excluding dotfiles).
        # Each test directory may contain one or more entrypoints:
        #   tests/<t>/main.c            -> ELF named <t>
        #   tests/<t>/main_<suffix>.c   -> ELF named <t>_<suffix>
        # Mirrored from the naming convention in the Makefile.
        testNames = builtins.filter (test: (builtins.substring 0 1 test) != ".") (
          builtins.attrNames (builtins.readDir ./tests)
        );

        # Returns the list of entrypoint filenames (basenames) for a test.
        entrySrcsFor =
          test:
          let
            entries = builtins.attrNames (builtins.readDir (./tests + "/${test}"));
            isEntry =
              f:
              f == "main.c"
              || (
                builtins.stringLength f > 7
                && builtins.substring 0 5 f == "main_"
                && builtins.substring (builtins.stringLength f - 2) 2 f == ".c"
              );
          in
          builtins.filter isEntry entries;

        # Given a test name and an entrypoint filename, compute the ELF basename.
        elfNameFor =
          test: entrySrc:
          if entrySrc == "main.c" then
            test
          else
            "${test}_${builtins.substring 5 (builtins.stringLength entrySrc - 7) entrySrc}";

        # Given a test name and an entrypoint filename, compute the expected.txt
        # filename to diff against. main.c uses expected.txt; main_<suffix>.c
        # uses expected_<suffix>.txt.
        expectedNameFor =
          entrySrc:
          if entrySrc == "main.c" then
            "expected.txt"
          else
            "expected_${builtins.substring 5 (builtins.stringLength entrySrc - 7) entrySrc}.txt";

        # Flat list of { test, entrySrc, elf } records — one per ELF that the
        # Makefile will produce.
        allElfs = lib.concatMap (
          test:
          lib.map (entrySrc: {
            inherit test entrySrc;
            elf = elfNameFor test entrySrc;
          }) (entrySrcsFor test)
        ) testNames;

        builtTestApps = pkgs.stdenv.mkDerivation {
          pname = "qemu-rv32-semihosting-wasm-tests";
          version = "0.1.0";
          src = ./.;
          nativeBuildInputs = [
            # For compiling towards our RISC-V target:
            crossPkgs.stdenv.cc
            targetNewlib

            # wasm2c and other related tools:
            patchedWabt

            # Regular (unwrapped) clang to compile C to WASM32. If we use the
            # Nix-wrapped clang, we get errors regarding multilib, etc.:
            pkgs.clang.cc
            pkgs.lld # Required, otherwise the compiler can't find the linker.
          ];
          makeFlags = [
            "TOOLCHAIN_PREFIX=riscv32-none-elf-"
            "NEWLIB_PREFIX=${targetNewlib}"
            "MARCH=${targetMarch}"
            "MABI=${targetMabi}"
          ];
          hardeningDisable = [
            "relro"
            "bindnow"
          ];
          installPhase = ''
            mkdir -p $out/bin
            ${lib.concatStringsSep "\n" (
              lib.map (e: ''
                cp ./build/${e.test}/${e.elf} $out/bin/
              '') allElfs
            )}
          '';
        };
      in
      {
        apps = lib.listToAttrs (
          lib.map (e: {
            name = "qemu-${e.elf}";
            value = {
              type = "app";
              program = "${
                pkgs.writeShellApplication {
                  name = "qemu-${e.elf}";
                  runtimeInputs = [ pkgs.qemu ];
                  text = ''
                    exec qemu-system-riscv32 \
                      -machine virt -bios none -nographic -semihosting \
                      -kernel ${builtTestApps}/bin/${e.elf} "$@"
                  '';
                }
              }/bin/qemu-${e.elf}";
            };
          }) allElfs
        );

        # `nix flake check` runs each ELF under QEMU and diffs its output
        # against the matching tests/<test>/expected*.txt. ELFs without an
        # expected file are skipped (they remain runnable via `nix run`).
        # The `formatting` check enforces treefmt.
        checks =
          (lib.listToAttrs (
            lib.concatMap (
              e:
              let
                expectedPath = ./tests + "/${e.test}/${expectedNameFor e.entrySrc}";
              in
              lib.optional (builtins.pathExists expectedPath) {
                name = "qemu-${e.elf}";
                value =
                  pkgs.runCommand "check-qemu-${e.elf}"
                    {
                      nativeBuildInputs = [ pkgs.qemu ];
                      expected = expectedPath;
                    }
                    ''
                      qemu-system-riscv32 \
                        -machine virt -bios none -nographic -semihosting \
                        -kernel ${builtTestApps}/bin/${e.elf} \
                        </dev/null >actual.txt
                      diff -u "$expected" actual.txt
                      touch $out
                    '';
              }
            ) allElfs
          ))
          // {
            formatting = treefmtEval.config.build.check self;
          };

        # `nix fmt` runs the treefmt wrapper across the tree.
        formatter = treefmtEval.config.build.wrapper;

        devShells.default = pkgs.mkShell {
          packages = builtTestApps.nativeBuildInputs ++ [
            # Development packages:
            pkgs.gnumake
            pkgs.gdb
            pkgs.qemu
          ];
          CROSS_COMPILE = "riscv32-none-elf-";
          NEWLIB_PREFIX = "${targetNewlib}";
          MARCH = targetMarch;
          MABI = targetMabi;
          hardeningDisable = [
            "relro"
            "bindnow"
          ];
        };
      }
    );
}
