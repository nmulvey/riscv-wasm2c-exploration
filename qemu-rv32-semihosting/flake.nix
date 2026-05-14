{
  description = "Bare-metal rv32 hello-world for QEMU `virt` with semihosting.";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    wabt-easm = {
      type = "git";
      url = "https://github.com/lschuermann/wabt-easm";
      ref = "easm";
      flake = false;
      submodules = true;
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
      treefmt-nix,
      wabt-easm,
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs { inherit system; };
        inherit (pkgs) lib;

        treefmtEval = treefmt-nix.lib.evalModule pkgs ./treefmt.nix;

        # Using `crossSystem` forces a rebuild of the entire compiler toolchain
        # (stage 0 and stage 1). We instead build on top of the Nix prebuilt
        # stdenv, and only override gcc + newlib for ABIs that don't match
        # the prebuilt defaults (rv32imafdc / ilp32d — hard-float).
        #
        # crossFor = forAllSystems (system: import nixpkgs {
        #   inherit system;
        #   crossSystem = {
        #     config = "riscv32-none-elf";
        #     libc = "newlib";
        #     gcc = { arch = ...; abi = ...; };
        #   };
        # });
        crossPkgs = pkgs.pkgsCross.riscv32-embedded;

        patchedWabt = pkgs.wabt.overrideAttrs (oldAttrs: {
          # patches = [ ./0001-wasm2c-wasm-rt-allow-overriding-WASM_RT_THREAD_LOCAL.patch ];
          src = wabt-easm;
        });

        # Build a gcc + newlib pair re-configured for the given march/mabi.
        #
        # The prebuilt cross-toolchain ships a single libgcc.a built for the
        # gcc-default arch (rv32imafdc / ilp32d — hard-float). Linking that
        # against e.g. soft-float rv32imac/ilp32 objects fails as soon as
        # gcc outlines anything into a libgcc helper (e.g. 64-bit shifts at
        # -Os). To target a different ABI we re-set gcc's configure-time
        # defaults so the libgcc baked into the next gcc build matches, and
        # rebuild newlib with matching flags. One-time gcc rebuild — only
        # paid when a non-default toolchain is actually forced.
        #
        # `buildPackages.gcc` is the cross-compiler that runs on the build
        # platform and targets riscv32 — distinct from `crossPkgs.gcc`,
        # which would be a (nonexistent) gcc that runs on riscv32 itself.
        mkRebuiltToolchain =
          march: mabi:
          let
            gccCc = crossPkgs.buildPackages.gcc.cc.overrideAttrs (old: {
              configureFlags = (old.configureFlags or [ ]) ++ [
                "--with-arch=${march}"
                "--with-abi=${mabi}"
              ];
            });
          in
          {
            inherit march mabi;
            # Re-wrap with the existing cc-wrapper so binutils / specs paths
            # stay wired up.
            cc = crossPkgs.stdenv.cc.override { cc = gccCc; };
            newlib = crossPkgs.newlib.overrideAttrs (_old: {
              CFLAGS_FOR_TARGET = "-O2 -march=${march} -mabi=${mabi} -mcmodel=medany";
            });
          };

        # Registry of supported RISC-V toolchain variants. Each entry
        # bundles a wrapped cc, a matching newlib, and the -march/-mabi
        # flags the Makefile expects. Add an entry here (and rebuild via
        # `mkRebuiltToolchain` if the ABI differs from the prebuilt
        # default) to introduce a new variant.
        #
        # `rv32imafdc` (hard-float) reuses the prebuilt Nix cross-toolchain
        # as-is — no gcc/newlib rebuild, so it evaluates and builds fast.
        # `rv32imac` (soft-float) pays the one-time compiler rebuild on
        # first use.
        toolchains = {
          rv32imafdc = {
            march = "rv32imafdc";
            mabi = "ilp32d";
            cc = crossPkgs.stdenv.cc;
            newlib = crossPkgs.newlib;
          };
          rv32imac = mkRebuiltToolchain "rv32imac" "ilp32";
        };

        # Arch used when an app / check / shell is referenced without an
        # explicit prefix. Picked to be the fast (no-rebuild) variant.
        defaultArch = "rv32imafdc";

        archs = builtins.attrNames toolchains;

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

        mkBuiltTestApps =
          arch:
          let
            tc = toolchains.${arch};
          in
          pkgs.stdenv.mkDerivation {
            pname = "qemu-rv32-semihosting-wasm-tests-${arch}";
            version = "0.1.0";
            src = ./.;
            nativeBuildInputs = [
              # For compiling towards our RISC-V target:
              tc.cc

              # Newlib is referenced by NEWLIB_PREFIX below (an absolute store
              # path), not by PATH, so it is not in nativeBuildInputs. Adding
              # it there triggers nixpkgs's cross-splicing, which rewrites
              # `crossPkgs.newlib` to a misconfigured `pkgs.newlib` whose
              # build fails ("cannot compute suffix of object files") because
              # no cross-compiler is in PATH during its own build.

              # wasm2c and other related tools:
              patchedWabt

              # Regular (unwrapped) clang to compile C to WASM32. If we use the
              # Nix-wrapped clang, we get errors regarding multilib, etc.:
              pkgs.clang.cc
              pkgs.lld # Required, otherwise the compiler can't find the linker.
            ];
            makeFlags = [
              "TOOLCHAIN_PREFIX=riscv32-none-elf-"
              "NEWLIB_PREFIX=${tc.newlib}"
              "MARCH=${tc.march}"
              "MABI=${tc.mabi}"
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

        # Lazy per-arch test-ELF bundles. Forced only when something
        # downstream (a `nix run` app, a `nix flake check` check, a
        # `nix develop` shell, etc.) actually needs the artifacts.
        builtByArch = lib.mapAttrs (arch: _: mkBuiltTestApps arch) toolchains;

        # Default arch gets bare names (`qemu-<elf>`); other archs are
        # prefixed (`qemu-<arch>-<elf>`).
        appName = arch: elf: if arch == defaultArch then "qemu-${elf}" else "qemu-${arch}-${elf}";

        mkApp =
          arch: e:
          let
            name = appName arch e.elf;
          in
          {
            inherit name;
            value = {
              type = "app";
              program = "${
                pkgs.writeShellApplication {
                  inherit name;
                  runtimeInputs = [ pkgs.qemu ];
                  text = ''
                    exec qemu-system-riscv32 \
                      -machine virt -bios none -nographic -semihosting \
                      -kernel ${builtByArch.${arch}}/bin/${e.elf} "$@"
                  '';
                }
              }/bin/${name}";
            };
          };

        mkCheck =
          arch: e:
          let
            expectedPath = ./tests + "/${e.test}/${expectedNameFor e.entrySrc}";
            name = appName arch e.elf;
          in
          lib.optional (builtins.pathExists expectedPath) {
            inherit name;
            value =
              pkgs.runCommand "check-${name}"
                {
                  nativeBuildInputs = [ pkgs.qemu ];
                  expected = expectedPath;
                }
                ''
                  qemu-system-riscv32 \
                    -machine virt -bios none -nographic -semihosting \
                    -kernel ${builtByArch.${arch}}/bin/${e.elf} \
                    </dev/null >actual.txt
                  diff -u "$expected" actual.txt
                  touch $out
                '';
          };

        mkDevShell =
          arch:
          let
            tc = toolchains.${arch};
          in
          pkgs.mkShell {
            packages = (mkBuiltTestApps arch).nativeBuildInputs ++ [
              # Development packages:
              pkgs.gnumake
              pkgs.gdb
              pkgs.qemu
            ];
            CROSS_COMPILE = "riscv32-none-elf-";
            NEWLIB_PREFIX = "${tc.newlib}";
            MARCH = tc.march;
            MABI = tc.mabi;
            hardeningDisable = [
              "relro"
              "bindnow"
            ];
          };
      in
      {
        # Apps for every (arch, elf) pair. Default-arch apps keep their
        # bare `qemu-<elf>` names; alternate archs are prefixed
        # (`qemu-rv32imac-<elf>`). None force a toolchain build until the
        # corresponding `nix run` is invoked.
        apps = lib.listToAttrs (lib.concatMap (arch: lib.map (mkApp arch) allElfs) archs);

        # Per-arch test-ELF bundles, plus a `default` alias for the
        # default arch. Build a non-default arch explicitly with
        # `nix build .#tests-rv32imac`.
        packages =
          (lib.mapAttrs' (arch: _: {
            name = "tests-${arch}";
            value = builtByArch.${arch};
          }) toolchains)
          // {
            default = builtByArch.${defaultArch};
          };

        # `nix flake check` runs each default-arch ELF under QEMU and
        # diffs against tests/<test>/expected*.txt. ELFs without an
        # expected file are skipped (they remain runnable via `nix run`).
        # Alternate archs are intentionally excluded so `nix flake check`
        # doesn't pull in their toolchain rebuilds — verify them with
        # `nix build .#tests-<arch>` when needed.
        # The `formatting` check enforces treefmt.
        checks = (lib.listToAttrs (lib.concatMap (mkCheck defaultArch) allElfs)) // {
          formatting = treefmtEval.config.build.check self;
        };

        # `nix fmt` runs the treefmt wrapper across the tree.
        formatter = treefmtEval.config.build.wrapper;

        # `nix develop` defaults to the default arch. `nix develop .#rv32imac`
        # (etc.) enters a shell wired up for an alternate arch — first
        # entry triggers the matching toolchain rebuild.
        devShells = (lib.mapAttrs (arch: _: mkDevShell arch) toolchains) // {
          default = mkDevShell defaultArch;
        };
      }
    );
}
