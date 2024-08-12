{
  description = "NixOS in MicroVMs";

  inputs.microvm.url = "github:astro/microvm.nix";
  inputs.microvm.inputs.nixpkgs.follows = "nixpkgs";

  outputs = { self, nixpkgs, microvm }:
    let system = "x86_64-linux";
    in {
      packages.${system} = {
        default = self.packages.${system}.my-microvm;
        my-microvm =
          self.nixosConfigurations.my-microvm.config.microvm.declaredRunner;
      };

      nixosConfigurations = {
        my-microvm = nixpkgs.lib.nixosSystem {
          inherit system;
          modules = [
            # relecant section
            # limitation: we should not pass things into extraArgs
            # goal write a nixos test against own config
            ({ pkgs, config, lib, ... }: {
              system.checks = [
                (pkgs.runNixosTest {
                  name = "example";
                  nodes.machine = { config, pkgs, ... }:
                    {

                    };
                  testScript = { nodes, ... }: ''

                    machine.wait_for_unit("default.target")
                    machine.succeed("su -- alice -c 'which firefox'")
                    machine.fail("su -- root -c 'which firefox'")
                  '';
                })
              ];
            })
            microvm.nixosModules.microvm
            {
              networking.hostName = "my-microvm";
              users.users.root.password = "";
              microvm = {
                volumes = [{
                  mountPoint = "/var";
                  image = "var.img";
                  size = 256;
                }];
                shares = [{
                  # use "virtiofs" for MicroVMs that are started by systemd
                  proto = "9p";
                  tag = "ro-store";
                  # a host's /nix/store will be picked up so that no
                  # squashfs/erofs will be built for it.
                  source = "/nix/store";
                  mountPoint = "/nix/.ro-store";
                }];

                hypervisor = "qemu";
                socket = "control.socket";
              };
            }
          ];
        };
      };
    };
}
