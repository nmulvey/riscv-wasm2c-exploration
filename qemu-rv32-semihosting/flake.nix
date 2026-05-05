{
  description = "Bare-metal rv32 hello-world for QEMU `virt` with semihosting.";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system: let
      pkgs = import nixpkgs { inherit system; };
      inherit (pkgs) lib;

      # Build all of our targets for this particular RISC-V architecture.
      targetMarch = "rv32imac";
      targetMabi  = "ilp32";

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

      testApps = [
        "00_semihosting-hello-world"
        "01_constant"
      ];

      builtTestApps = pkgs.stdenv.mkDerivation {
        pname = "qemu-rv32-semihosting-wasm-tests";
        version = "0.1.0";
        src = ./.;
        nativeBuildInputs = [
          crossPkgs.stdenv.cc
          targetNewlib
          patchedWabt
        ];
        makeFlags = [
          "TOOLCHAIN_PREFIX=riscv32-none-elf-"
          "NEWLIB_PREFIX=${targetNewlib}"
          "MARCH=${targetMarch}"
          "MABI=${targetMabi}"
        ];
        hardeningDisable = [ "relro" "bindnow" ];
        installPhase = ''
              mkdir -p $out/bin
              ${
                lib.concatStringsSep "\n" (
                  lib.map (testName: ''
                    cp ./build/${testName}/${testName} $out/bin/
                  '') testApps
                )
              }
            '';
      };
    in {
      apps = lib.genAttrs' testApps (testName: lib.nameValuePair
        "qemu-${testName}"
        {
          type = "app";
          program = "${pkgs.writeShellApplication {
            name = "qemu-${testName}";
            runtimeInputs = [ pkgs.qemu ];
            text = ''
              exec qemu-system-riscv32 \
                -machine virt -bios none -nographic -semihosting \
                -kernel ${builtTestApps}/bin/${testName} "$@"
            '';
          }}/bin/qemu-${testName}";
        }
      );

      devShells.default = pkgs.mkShell {
        packages = [
          crossPkgs.stdenv.cc
          targetNewlib
          patchedWabt
          pkgs.qemu
          pkgs.gnumake
          pkgs.gdb
        ];
        CROSS_COMPILE = "riscv32-none-elf-";
        NEWLIB_PREFIX = "${targetNewlib crossPkgs}";
        MARCH = targetMarch;
        MABI  = targetMabi;
        hardeningDisable = [ "relro" "bindnow" ];
      };
    });
}
