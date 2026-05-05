{
  description = "Bare-metal rv32 hello-world for QEMU `virt` with semihosting.";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs = { self, nixpkgs }:
    let
      systems = [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ];
      forAllSystems = nixpkgs.lib.genAttrs systems;
      pkgsFor = forAllSystems (system: import nixpkgs { inherit system; });

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

      targetNewlib = crossPkgs: crossPkgs.newlib.overrideAttrs (_old: {
        CFLAGS_FOR_TARGET = "-O2 -march=rv32imac -mabi=ilp32 -mcmodel=medany";
      });

      patchedWabt = pkgs: pkgs.wabt.overrideAttrs (oldAttrs: {
        patches = [ ./0001-wasm2c-wasm-rt-allow-overriding-WASM_RT_THREAD_LOCAL.patch ];
      });

      mkPackages = system:
        let
          pkgs = pkgsFor.${system};

          # Use the Nix prebuilt stdenv, then override newlib:
          crossPkgs = pkgs.pkgsCross.riscv32-embedded;

          # If it didn't want to override newlib we'd use:
          # crossPkgs = crossFor system;
        in {
          hello = pkgs.stdenv.mkDerivation {
            pname = "qemu-rv32-hello";
            version = "0.1.0";
            src = ./.;
            nativeBuildInputs = [
              crossPkgs.stdenv.cc
              (targetNewlib crossPkgs)
              (patchedWabt pkgs)
            ];
            makeFlags = [
              "TOOLCHAIN_PREFIX=riscv32-none-elf-"
              "NEWLIB_PREFIX=${targetNewlib crossPkgs}"
              "MARCH=${targetMarch}"
              "MABI=${targetMabi}"
            ];
            hardeningDisable = [ "relro" "bindnow" ];
            installPhase = ''
              mkdir -p $out/bin
              cp build/hello.elf $out/bin/
            '';
          };

          run-hello = pkgs.writeShellApplication {
            name = "run-hello";
            runtimeInputs = [ pkgs.qemu ];
            text = ''
              exec qemu-system-riscv32 \
                -machine virt -bios none -nographic -semihosting \
                -kernel ${self.packages.${system}.hello}/bin/hello.elf "$@"
            '';
          };
        };
    in {
      devShells = forAllSystems (system:
        let
          pkgs = pkgsFor.${system};
          crossPkgs = pkgs.pkgsCross.riscv32-embedded;
          # crossPkgs = crossFor.${system};
        in {
          default = pkgs.mkShell {
            packages = [
              crossPkgs.stdenv.cc
              (targetNewlib crossPkgs)
              pkgs.qemu
              pkgs.gnumake
              pkgs.gdb
              (patchedWabt pkgs)
            ];
            CROSS_COMPILE = "riscv32-none-elf-";
            NEWLIB_PREFIX = "${targetNewlib crossPkgs}";
            MARCH = targetMarch;
            MABI  = targetMabi;
            hardeningDisable = [ "relro" "bindnow" ];
          };
        });

      packages = forAllSystems (system:
        let p = mkPackages system; in {
          default = p.hello;
          hello = p.hello;
          run-hello = p.run-hello;
        });

      apps = forAllSystems (system:
        let p = mkPackages system; in {
          default = {
            type = "app";
            program = "${p.run-hello}/bin/run-hello";
          };
          run = {
            type = "app";
            program = "${p.run-hello}/bin/run-hello";
          };
        });
    };
}
