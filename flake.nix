{
  description = "vim-fugitive, but using firvish.nvim";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    pre-commit-hooks-nix.url = "github:cachix/pre-commit-hooks.nix";
  };

  outputs = {flake-parts, ...} @ inputs:
    flake-parts.lib.mkFlake {inherit inputs;} {
      imports = [
        inputs.pre-commit-hooks-nix.flakeModule
      ];

      systems = ["x86_64-linux" "aarch64-darwin"];
      perSystem = {
        config,
        pkgs,
        ...
      }: {
        apps.default.program = pkgs.writeShellApplication {
          name = "update-docs";
          runtimeInputs = with pkgs; [lemmy-help];
          text = ''
            lemmy-help lua/firvish/extensions/*.lua > doc/git-firvish.txt
            nvim --headless -c 'helptags doc/' -c q
          '';
        };

        devShells.default = pkgs.mkShell {
          name = "git.firvish";
          shellHook = ''
            ${config.pre-commit.installationScript}
          '';
        };

        formatter = pkgs.alejandra;

        pre-commit = {
          check.enable = true;
          settings.hooks = {
            alejandra.enable = true;
            stylua.enable = true;
          };
        };
      };
    };
}
