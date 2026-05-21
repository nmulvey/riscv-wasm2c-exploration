{
  description = "Bare-metal rv32 hello-world for QEMU `virt` with semihosting.";

  # Make submodules available in Nix build sandbox:
  inputs.self.submodules = true;

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/master";
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

        # Build a compiler-rt for the target platform
        mkCompilerRtForTarget =
          { march, mabi }:
          let
            hostLlvm = pkgs.llvmPackages_22;

            # A clang wrapper that:
            #  - is host-built (no cross-bootstrap)
            #  - has libc = null, libcxx = null  → haveLibc/haveLibcxx false in compiler-rt
            #  - has isClang = true              → satisfies the broken= check
            #  - emits riscv32-none-elf code     → CMAKE_C_COMPILER_TARGET works
            clangForTarget = pkgs.wrapCCWith {
              cc = hostLlvm.clang-unwrapped;
              libc = null;
              libcxx = null;
              bintools = pkgs.bintoolsNoLibc; # not used for linking; STATIC_LIBRARY try_compile avoids it
              extraBuildCommands = ''
                echo "-target riscv32-none-elf" >> $out/nix-support/cc-cflags
                echo "-march=${march} -mabi=${mabi} -mno-relax" >> $out/nix-support/cc-cflags
              '';
            };

            # Required because `compiler-rt` wants to be built with clang, and
            # checks that it's stdenv is a clang stdenv. However, there are a
            # million errors when we try to get a `useLLVM` stdenv for
            # riscv32-embedded. So we hack one together here:
            customStdenv = crossPkgs.overrideCC crossPkgs.stdenvNoCC clangForTarget;

            compilerRtPkg =
              (hostLlvm.compiler-rt.override {
                stdenv = customStdenv;

                # useLLVM isn't set on hostPlatform (we're avoiding pkgsCross's useLLVM
                # bootstrap), so two flags that the derivation only adds under useLLVM
                # need to come in via this escape hatch:
                devExtraCmakeFlags = [
                  "-DCMAKE_TRY_COMPILE_TARGET_TYPE=STATIC_LIBRARY"
                  "-DCOMPILER_RT_BUILD_BUILTINS=ON"
                ];
              }).overrideAttrs
                (old: {
                  # Not supported on embedded RISC-V targets:
                  hardeningDisable = (old.hardeningDisable or [ ]) ++ [ "zerocallusedregs" ];
                });
          in
          "${compilerRtPkg}/lib/baremetal/libclang_rt.builtins-riscv32.a";

        patchedWabt = pkgs.wabt.overrideAttrs (oldAttrs: {
          patches = [ ./0001-wasm2c-wasm-rt-allow-overriding-WASM_RT_THREAD_LOCAL.patch ];
        });

        # libgcc.a path for a toolchain entry. We compute it in the flake
        # (rather than having Make shell out to gcc) so clang derivations
        # don't need the gcc wrapper in nativeBuildInputs at all — the
        # archive is referenced as a plain store path.
        libgccFromGcc = gccPkg: "${gccPkg}/lib/gcc/riscv32-none-elf/${gccPkg.version}/libgcc.a";

        # Registry of supported RISC-V toolchain variants. Each entry
        # bundles a wrapped cc, a matching newlib, the -march/-mabi
        # flags the Makefile expects, and a `useClang` flag that picks
        # between gcc (default) and clang+lld for the compile/link steps.
        # Add an entry here (and rebuild via `mkRebuiltToolchain` if the
        # ABI differs from the prebuilt default) to introduce a new variant.
        #
        # `rv32imafdc` (hard-float) reuses the prebuilt Nix cross-toolchain
        # as-is — no gcc/newlib rebuild, so it evaluates and builds fast.
        # `rv32imafdc-clang` likewise — it just drives the compile/link
        # with clang+lld against the prebuilt gcc-built newlib.
        # `rv32imac` (soft-float) pays the one-time gcc rebuild on first
        # use. `rv32imac-clang` rides on top of `rv32imac`'s newlib and
        # binutils but drives compilation/linking with clang+lld.
        mkRv32imafdcToolchain =
          { compilerFamily, rtlib }:
          {
            inherit compilerFamily rtlib;

            march = "rv32imafdc";
            mabi = "ilp32d";
          }
          // (lib.optionalAttrs (compilerFamily == "gcc") {
            cc = crossPkgs.stdenv.cc;
            libgcc = libgccFromGcc crossPkgs.buildPackages.gcc.cc;
            newlib = crossPkgs.newlib;
          })
          // (
            lib.optionalAttrs (compilerFamily == "clang") {
              # Unwrapped clang compiler (we don't want the wrapped one in path,
              # that conflicts with manual cross compile options, at least for the
              # WASM target).
              cc = pkgs.clang.cc;
              # Still build newlib using gcc---if we want to use `clang`, we're back
              # to having to get a clang stdenv and having to resolve a bunch of
              # bugs in upstream clang and Nixpkgs.
              newlib = crossPkgs.newlib;
            }
            // (lib.optionalAttrs (rtlib == "libgcc") {
              libgcc = libgccFromGcc crossPkgs.buildPackages.gcc.cc;
            })
            // (lib.optionalAttrs (rtlib == "compiler-rt") {
              compiler-rt = mkCompilerRtForTarget {
                march = "rv32imafdc";
                mabi = "ilp32d";
              };
            })
          );

        toolchains = {
          rv32imafdc-gcc = mkRv32imafdcToolchain {
            compilerFamily = "gcc";
            rtlib = "libgcc"; # only libgcc supported
          };
          rv32imafdc-clang-libgcc = mkRv32imafdcToolchain {
            compilerFamily = "clang";
            rtlib = "libgcc";
          };
          rv32imafdc-clang-compiler-rt = mkRv32imafdcToolchain {
            compilerFamily = "clang";
            rtlib = "compiler-rt";
          };
        };

        # Arch used when an app / check / shell is referenced without an
        # explicit prefix. Picked to be the fast (no-rebuild) variant.
        defaultArch = "rv32imafdc-clang-libgcc";

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
              # wasm2c and other related tools:
              patchedWabt

              # Regular (unwrapped) clang to compile C to WASM32. If we use the
              # Nix-wrapped clang, we get errors regarding multilib, etc.:
              pkgs.clang.cc
              pkgs.lld # Required, otherwise the compiler can't find the linker.

              # Add the toolchain's compiler for the target (may be identical to
              # pkgs.clang.cc for clang toolchains, but that's harmless):
              tc.cc

              # Newlib is referenced by NEWLIB_PREFIX below (an absolute store
              # path), not by PATH, so it is not in nativeBuildInputs. Adding
              # it there triggers nixpkgs's cross-splicing, which rewrites
              # `crossPkgs.newlib` to a misconfigured `pkgs.newlib` whose
              # build fails ("cannot compute suffix of object files") because
              # no cross-compiler is in PATH during its own build.
            ]
            # llvm-size is needed by the Makefile's `SIZE := llvm-size`
            # line under USE_CLANG=1. bintools-unwrapped also brings
            # llvm-objcopy and friends if anything reaches for them.
            ++ lib.optional (tc.compilerFamily == "clang") pkgs.llvmPackages.bintools-unwrapped;

            makeFlags = [
              "MARCH=${tc.march}"
              "MABI=${tc.mabi}"
              "NEWLIB_PREFIX=${tc.newlib}"
              "WABT_INCLUDE=${patchedWabt}/include"
            ]
            ++ lib.optionals (tc.compilerFamily == "gcc") [
              "USE_CLANG=0"
              "TOOLCHAIN_PREFIX=riscv32-none-elf-"
            ]
            ++ lib.optionals (tc.compilerFamily == "clang") [
              "USE_CLANG=1"
            ]
            ++ lib.optionals (tc.rtlib == "libgcc") [
              "RTLIB=libgcc"
              "LIBGCC_PATH=${tc.libgcc}"
            ]
            ++ lib.optionals (tc.rtlib == "compiler-rt") [
              "RTLIB=compiler-rt"
              "COMPILER_RT_BUILTINS=${tc.compiler-rt}"
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

        appName = arch: elf: "qemu-${arch}-${elf}";

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
              pkgs.runCommand "check-${arch}-${name}"
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
            MARCH = tc.march;
            MABI = tc.mabi;

            NEWLIB_PREFIX = "${tc.newlib}";
            WABT_INCLUDE = "${patchedWabt}/include";

            USE_CLANG = if (tc.compilerFamily == "clang") then "1" else "0";

            RTLIB = tc.rtlib;
            LIBGCC_PATH = if (tc.rtlib == "libgcc") then tc.libgcc else null;
            COMPILER_RT_BUILTINS = if (tc.rtlib == "compiler-rt") then tc.compiler-rt else null;

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
