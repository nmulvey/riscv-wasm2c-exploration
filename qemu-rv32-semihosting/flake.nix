{
  description = "Bare-metal rv32 hello-world for QEMU `virt` with semihosting.";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs = { self, nixpkgs }:
    let
      systems = [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ];
      forAllSystems = nixpkgs.lib.genAttrs systems;
      pkgsFor = forAllSystems (system: import nixpkgs { inherit system; });

      # nixpkgs ships newlib for riscv32-none-elf built only for rv32gc/ilp32d.
      # Picolibc 1.8.9 currently fails to build on this channel (gcc 15 +
      # crt0-semihost CFI issue), so we use newlib's semihost.specs which
      # provides the same printf/exit-via-semihosting story.
      #
      # TODO: why can't we use rv32i here?
      flakeMarch = "rv32gc";
      flakeMabi  = "ilp32d";

      mkPackages = system:
        let
          pkgs = pkgsFor.${system};
          cross = pkgs.pkgsCross.riscv32-embedded;
        in {
          hello = pkgs.stdenv.mkDerivation {
            pname = "qemu-rv32-hello";
            version = "0.1.0";
            src = ./.;
            nativeBuildInputs = [ cross.stdenv.cc ];
            makeFlags = [
              "CROSS_COMPILE=riscv32-none-elf-"
              "MARCH=${flakeMarch}"
              "MABI=${flakeMabi}"
            ];
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
          cross = pkgs.pkgsCross.riscv32-embedded;
        in {
          default = pkgs.mkShell {
            packages = [
              cross.stdenv.cc
              pkgs.qemu
              pkgs.gnumake
              pkgs.gdb
            ];
            CROSS_COMPILE = "riscv32-none-elf-";
            MARCH = flakeMarch;
            MABI  = flakeMabi;
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
