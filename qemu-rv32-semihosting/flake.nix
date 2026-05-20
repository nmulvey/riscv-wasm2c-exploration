{
  description = "Bare-metal wasm2c tests for QEMU (rv32 `virt`, Cortex-M4 `mps2-an386`) with semihosting.";

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

        # ARM Cortex-M compiler-rt builtins. Unlike RISC-V, the nixpkgs
        # `pkgsCross.arm-embedded.llvmPackages.compiler-rt` derivation is
        # usable nearly as-is: it builds with the cross gcc (no clang-stdenv
        # hack needed), produces a `libclang_rt.builtins-arm.a` for the
        # baremetal target, and respects the cc-wrapper's NIX_CFLAGS_COMPILE
        # passthrough. The only thing we need to override is the default
        # multilib — pkgsCross.arm-embedded's gcc was built --disable-multilib
        # --with-float=soft (armv4t), so without an explicit -mcpu/-mthumb/
        # -mfpu/-mfloat-abi the resulting builtins are v4t and the link
        # later fails with VFP-register ABI mismatches.
        #
        # We can't pipe -mcpu… through cmakeFlags (CMake splits CMAKE_C_FLAGS
        # on whitespace when it arrives as one shell argument), so we inject
        # via NIX_CFLAGS_COMPILE_<target_triple>, which the gcc wrapper
        # appends to every cc/as invocation it issues.
        mkArmCompilerRtBuiltins =
          { mcpu, mfloatAbi, mfpu ? null }:
          let
            flagStr = lib.concatStringsSep " " (
              [
                "-mcpu=${mcpu}"
                "-mthumb"
                "-mfloat-abi=${mfloatAbi}"
              ]
              ++ lib.optional (mfpu != null) "-mfpu=${mfpu}"
            );
            armRt = pkgs.pkgsCross.arm-embedded.llvmPackages.compiler-rt.overrideAttrs (old: {
              env = (old.env or { }) // {
                NIX_CFLAGS_COMPILE_arm_none_eabi = flagStr;
              };
            });
          in
          "${armRt}/lib/baremetal/libclang_rt.builtins-arm.a";

        patchedWabt = pkgs.wabt.overrideAttrs (oldAttrs: {
          patches = [ ./0001-wasm2c-wasm-rt-allow-overriding-WASM_RT_THREAD_LOCAL.patch ];
        });

        # gcc-arm-embedded sets `version = "15.2.rel1"` but the on-disk
        # `lib/gcc/arm-none-eabi/<X>` subdir is named after the underlying
        # gcc release ("15.2.1"). nixpkgs's riscv32-embedded cross gcc
        # happens to use the same string for both. Stripping `rel` is the
        # one-line transform that recovers the subdir name from the package
        # version for both layouts — it's a no-op on strings that don't
        # contain "rel". We avoid IFD by *not* using `builtins.readDir` on
        # the gcc store path.
        gccLibSubdirVersion = gccPkg: lib.replaceStrings [ "rel" ] [ "" ] gccPkg.version;

        # libgcc.a path for a toolchain entry. We compute it in the flake
        # (rather than having Make shell out to gcc) so clang derivations
        # don't need the gcc wrapper in nativeBuildInputs at all — the
        # archive is referenced as a plain store path.
        #
        # `multilibSubdir` is "" for toolchains without multilib (e.g. the
        # nixpkgs riscv32 cross-toolchain is built --disable-multilib) and
        # something like "thumb/v7e-m+fp/hard" for gcc-arm-embedded.
        libgccFromGcc =
          {
            gccPkg,
            triple,
            multilibSubdir ? "",
          }:
          let
            base = "${gccPkg}/lib/gcc/${triple}/${gccLibSubdirVersion gccPkg}";
          in
          if multilibSubdir == "" then "${base}/libgcc.a" else "${base}/${multilibSubdir}/libgcc.a";

        # Toolchain entries are records that describe everything downstream
        # consumers (build, run, check, dev-shell) need to know about an
        # (ISA family, sub-arch, compiler, rtlib) tuple. Every entry shares
        # the same top-level keys regardless of ISA family so the consumers
        # don't have to special-case:
        #
        #   archFamily       : "riscv32" | "arm" — dispatches Makefile and
        #                      qemu wiring. Adding a third family means
        #                      adding cases here and in the Makefile's
        #                      per-family block.
        #   targetTriple     : binutils triple, doubles as NEWLIB_PREFIX subdir
        #   toolchainPrefix  : e.g. "riscv32-none-elf-" / "arm-none-eabi-"
        #   crt0Src          : relative path under src/
        #   linkScript       : relative path under src/
        #   qemuSystem       : "qemu-system-<X>" binary name
        #   qemuMachine      : -machine value
        #   qemuExtra        : list of extra flags (e.g. ["-bios" "none"])
        #   abiMakeFlags     : list of "NAME=value" makeFlags carrying the
        #                      family-specific ABI selection (MARCH/MABI on
        #                      RISC-V; MCPU/MTHUMB/MFLOAT_ABI/MFPU on ARM).
        #                      The Makefile's per-family block consumes these.
        #   compilerFamily   : "gcc" | "clang"
        #   rtlib            : "libgcc" | "compiler-rt"
        #   cc               : compiler derivation (added to nativeBuildInputs)
        #   newlib           : path passed as NEWLIB_PREFIX
        #   libgcc           : store path to libgcc.a (clang+libgcc only)
        #   compiler-rt      : store path to compiler-rt builtins (clang+compiler-rt only)
        #
        # Registry of supported RISC-V toolchain variants:
        #   `rv32imafdc` (hard-float) reuses the prebuilt Nix cross-toolchain
        #     as-is — no gcc/newlib rebuild, so it evaluates and builds fast.
        #   `rv32imafdc-clang` likewise — it just drives the compile/link
        #     with clang+lld against the prebuilt gcc-built newlib.
        #   `rv32imac` (soft-float) would pay the one-time gcc rebuild on
        #     first use. `rv32imac-clang` rides on top of `rv32imac`'s
        #     newlib and binutils but drives compilation/linking with clang+lld.
        mkRv32imafdcToolchain =
          { compilerFamily, rtlib }:
          let
            march = "rv32imafdc";
            mabi = "ilp32d";
            triple = "riscv32-none-elf";
            libgccPath = libgccFromGcc {
              gccPkg = crossPkgs.buildPackages.gcc.cc;
              inherit triple;
            };
          in
          {
            inherit compilerFamily rtlib;

            archFamily = "riscv32";
            targetTriple = triple;
            toolchainPrefix = "${triple}-";

            inherit march mabi;
            abiMakeFlags = [
              "MARCH=${march}"
              "MABI=${mabi}"
            ];

            crt0Src = "src/crt0.S";
            linkScript = "src/link.ld";

            qemuSystem = "qemu-system-riscv32";
            qemuMachine = "virt";
            qemuExtra = [
              "-bios"
              "none"
            ];
          }
          // (lib.optionalAttrs (compilerFamily == "gcc") {
            cc = crossPkgs.stdenv.cc;
            libgcc = libgccPath;
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
              libgcc = libgccPath;
            })
            // (lib.optionalAttrs (rtlib == "compiler-rt") {
              compiler-rt = mkCompilerRtForTarget {
                inherit march mabi;
              };
            })
          );

        # ARM Cortex-M toolchain variants, fed by ARM's official prebuilt
        # `gcc-arm-embedded` (multilib). The package bundles arm-none-eabi-gcc,
        # binutils, newlib, libgcc, and librdimon — for the gcc path that's
        # everything; the clang path drives compilation/linking with clang+lld
        # but still pulls libgcc / newlib / librdimon from gcc-arm-embedded's
        # prefix (the multilib subdir picked at flake-eval time).
        #
        # Currently only the Cortex-M4F (mps2-an386) variant is wired up; add
        # a new entry by passing different cpu / qemuMachine / multilibSubdir.
        mkArmCortexMToolchain =
          {
            compilerFamily,
            rtlib,
            mcpu,
            mfloatAbi,
            mfpu ? null,
            multilibSubdir,
            qemuMachine,
            crt0Src ? "src/crt0_arm_v7m.S",
            linkScript,
            clangTarget ? "thumbv7em-none-eabihf",
          }:
          let
            triple = "arm-none-eabi";
            armGcc = pkgs.gcc-arm-embedded;
            libgccPath = libgccFromGcc {
              gccPkg = armGcc;
              inherit triple multilibSubdir;
            };
            # Path that the Makefile passes to ld as -L. On gcc-arm-embedded
            # the *top-level* arm-none-eabi/lib holds the default (armv4t
            # soft-float) multilib, so we point ld at the cortex-m4 subdir
            # instead. Without this, clang+lld would silently link the wrong
            # newlib/librdimon and produce VFP/Thumb-ABI mismatches at link
            # time.
            newlibLibDir = "${armGcc}/${triple}/lib/${multilibSubdir}";
          in
          {
            inherit
              compilerFamily
              rtlib
              mcpu
              mfloatAbi
              mfpu
              ;

            archFamily = "arm";
            targetTriple = triple;
            toolchainPrefix = "${triple}-";
            clangTargetTriple = clangTarget;

            abiMakeFlags = [
              "MCPU=${mcpu}"
              "MTHUMB=1"
              "MFLOAT_ABI=${mfloatAbi}"
              "CLANG_TARGET=${clangTarget}"
            ]
            ++ lib.optional (mfpu != null) "MFPU=${mfpu}";

            inherit crt0Src linkScript;

            qemuSystem = "qemu-system-arm";
            inherit qemuMachine;
            qemuExtra = [ ];
          }
          // (lib.optionalAttrs (compilerFamily == "gcc") {
            # gcc-arm-embedded is fully self-contained: cc, ld, newlib,
            # libgcc, librdimon all live under it and the gcc driver
            # already adds the correct multilib subdir to ld's search
            # path. Setting NEWLIB_PREFIX would prepend the *top-level*
            # arm-none-eabi/lib (containing the wrong-multilib default
            # libs) ahead of gcc's auto-paths, so we suppress it here.
            cc = armGcc;
            newlib = armGcc;
            libgcc = libgccPath;
            passNewlibPrefix = false;
          })
          // (
            lib.optionalAttrs (compilerFamily == "clang") {
              # Unwrapped clang, matching the RISC-V clang variants. We use
              # gcc-arm-embedded *only* as a source of pre-built libraries
              # (libc, librdimon, libgcc) — the compile/link driver is host
              # clang with --target=thumbvN-none-eabi[hf] and lld.
              cc = pkgs.clang.cc;
              newlib = armGcc;
              # Override the default $(NEWLIB_PREFIX)/$(TARGET_TRIPLE)/lib
              # (which is the v4t multilib) with the cortex-m subdir.
              newlibLibDir = newlibLibDir;
            }
            // (lib.optionalAttrs (rtlib == "libgcc") {
              libgcc = libgccPath;
            })
            // (lib.optionalAttrs (rtlib == "compiler-rt") {
              compiler-rt = mkArmCompilerRtBuiltins { inherit mcpu mfloatAbi mfpu; };
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

          arm-cortex-m4-gcc = mkArmCortexMToolchain {
            compilerFamily = "gcc";
            rtlib = "libgcc";
            mcpu = "cortex-m4";
            mfloatAbi = "hard";
            mfpu = "fpv4-sp-d16";
            # `arm-none-eabi-gcc -print-multi-directory -mcpu=cortex-m4
            #  -mthumb -mfloat-abi=hard -mfpu=fpv4-sp-d16` → thumb/v7e-m+fp/hard
            multilibSubdir = "thumb/v7e-m+fp/hard";
            qemuMachine = "mps2-an386";
            linkScript = "src/link_mps2_an386.ld";
          };
          arm-cortex-m4-clang-libgcc = mkArmCortexMToolchain {
            compilerFamily = "clang";
            rtlib = "libgcc";
            mcpu = "cortex-m4";
            mfloatAbi = "hard";
            mfpu = "fpv4-sp-d16";
            multilibSubdir = "thumb/v7e-m+fp/hard";
            qemuMachine = "mps2-an386";
            linkScript = "src/link_mps2_an386.ld";
          };
          arm-cortex-m4-clang-compiler-rt = mkArmCortexMToolchain {
            compilerFamily = "clang";
            rtlib = "compiler-rt";
            mcpu = "cortex-m4";
            mfloatAbi = "hard";
            mfpu = "fpv4-sp-d16";
            multilibSubdir = "thumb/v7e-m+fp/hard";
            qemuMachine = "mps2-an386";
            linkScript = "src/link_mps2_an386.ld";
          };
        };

        # Arch used when an app / check / shell is referenced without an
        # explicit prefix. Picked to be the fast (no-rebuild) variant.
        defaultArch = "rv32imafdc-clang-libgcc";

        # Archs run as part of `nix flake check`. Includes the RISC-V
        # default plus the ARM Cortex-M variant — both are prebuilt-only
        # (no per-checkout toolchain rebuild), so the marginal cost of
        # running both check sets is just QEMU execution time.
        checkArchs = [
          defaultArch
          "arm-cortex-m4-gcc"
          "arm-cortex-m4-clang-libgcc"
          "arm-cortex-m4-clang-compiler-rt"
        ];

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
            pname = "qemu-semihosting-wasm-tests-${arch}";
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
              "ARCH_FAMILY=${tc.archFamily}"
              "TARGET_TRIPLE=${tc.targetTriple}"
              "CRT0_SRC=${tc.crt0Src}"
              "LINK_SCRIPT=${tc.linkScript}"
              "WABT_INCLUDE=${patchedWabt}/include"
            ]
            # NEWLIB_PREFIX forces an explicit -I/-L override. Skip it on
            # toolchains whose bundled multilib newlib is already correct
            # (gcc-arm-embedded driving gcc): adding -L<top>/arm-none-eabi/lib
            # *ahead* of gcc's auto-computed multilib path drags in the
            # default (armv4t soft-float) variant and breaks the link.
            ++ lib.optional (tc.passNewlibPrefix or true) "NEWLIB_PREFIX=${tc.newlib}"
            # NEWLIB_LIBDIR overrides the derived $(NEWLIB_PREFIX)/$(TARGET_TRIPLE)/lib.
            # ARM clang sets this to the cortex-m multilib subdir so -lc /
            # -lrdimon resolve to the right ABI; RISC-V's --disable-multilib
            # cross-toolchain leaves it unset (the top-level lib is right).
            ++ lib.optional (tc ? newlibLibDir) "NEWLIB_LIBDIR=${tc.newlibLibDir}"
            ++ tc.abiMakeFlags
            ++ lib.optionals (tc.compilerFamily == "gcc") [
              "USE_CLANG=0"
              "TOOLCHAIN_PREFIX=${tc.toolchainPrefix}"
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

        # Shared qemu invocation used by both `mkApp` (nix run) and
        # `mkCheck` (nix flake check). Reads qemuSystem / qemuMachine /
        # qemuExtra off the toolchain so each ISA family supplies its own.
        qemuCmd =
          tc:
          lib.concatStringsSep " " (
            [
              tc.qemuSystem
              "-machine"
              tc.qemuMachine
            ]
            ++ tc.qemuExtra
            ++ [
              "-nographic"
              "-semihosting"
            ]
          );

        mkApp =
          arch: e:
          let
            tc = toolchains.${arch};
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
                    exec ${qemuCmd tc} \
                      -kernel ${builtByArch.${arch}}/bin/${e.elf} "$@"
                  '';
                }
              }/bin/${name}";
            };
          };

        mkCheck =
          arch: e:
          let
            tc = toolchains.${arch};
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
                  ${qemuCmd tc} \
                    -kernel ${builtByArch.${arch}}/bin/${e.elf} \
                    </dev/null >actual.txt
                  diff -u "$expected" actual.txt
                  touch $out
                '';
          };

        # The dev shell mirrors mkBuiltTestApps's makeFlags as a set of
        # environment variables (Make picks them up because they're exported
        # by `nix develop`). Anything `mkBuiltTestApps` passes via makeFlags
        # should be representable as an env var here so `make` inside the
        # shell behaves the same as the sandboxed flake build.
        mkDevShell =
          arch:
          let
            tc = toolchains.${arch};
            # Translate `tc.abiMakeFlags` (list of "NAME=value") into an
            # attrset for mkShell. Splitting on the first "=" only — values
            # shouldn't contain "=" but be safe.
            abiEnv = lib.listToAttrs (
              lib.map (s: {
                name = lib.elemAt (lib.splitString "=" s) 0;
                value = lib.concatStringsSep "=" (lib.tail (lib.splitString "=" s));
              }) tc.abiMakeFlags
            );
          in
          pkgs.mkShell (
            {
              packages = (mkBuiltTestApps arch).nativeBuildInputs ++ [
                # Development packages:
                pkgs.gnumake
                pkgs.gdb
                pkgs.qemu
              ];

              ARCH_FAMILY = tc.archFamily;
              TARGET_TRIPLE = tc.targetTriple;
              CROSS_COMPILE = tc.toolchainPrefix;
              TOOLCHAIN_PREFIX = tc.toolchainPrefix;

              CRT0_SRC = tc.crt0Src;
              LINK_SCRIPT = tc.linkScript;

              NEWLIB_PREFIX = if (tc.passNewlibPrefix or true) then "${tc.newlib}" else null;
              NEWLIB_LIBDIR = if (tc ? newlibLibDir) then tc.newlibLibDir else null;
              WABT_INCLUDE = "${patchedWabt}/include";

              USE_CLANG = if (tc.compilerFamily == "clang") then "1" else "0";

              RTLIB = tc.rtlib;
              LIBGCC_PATH = if (tc.rtlib == "libgcc") then tc.libgcc else null;
              COMPILER_RT_BUILTINS = if (tc.rtlib == "compiler-rt") then tc.compiler-rt else null;

              hardeningDisable = [
                "relro"
                "bindnow"
              ];
            }
            // abiEnv
          );
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

        # `nix flake check` runs every ELF in `checkArchs` under QEMU and
        # diffs against tests/<test>/expected*.txt. ELFs without an
        # expected file are skipped (they remain runnable via `nix run`).
        # Alternate RISC-V archs that pay a gcc/newlib rebuild are
        # intentionally excluded — verify them with `nix build .#tests-<arch>`.
        # The `formatting` check enforces treefmt.
        checks =
          (lib.listToAttrs (lib.concatMap (arch: lib.concatMap (mkCheck arch) allElfs) checkArchs))
          // {
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
