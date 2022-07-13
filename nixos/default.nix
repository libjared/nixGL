{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.nixgl;
in {
  options.nixgl = {
    # only supports zsh at the moment
    # only supports intel at the moment

    enable = mkEnableOption "NixGL, an OpenGL provider for non-NixOS";

    # vendor = mkOption {
    #   type = with types; nullOr (enum [ "intel" ]);
    #   default = null;
    #   example = "intel";
    #   description = ''
    #     The vendor of the GL drivers to load.
    #
    #     This determines the value of <envar>LD_LIBRARY_PATH</envar>, etc.,
    #     which will be defined for all shells.
    #   '';
    # };

    enable32bits = mkOption {
      type = types.bool;
      default = true;
      description = ''
        Enable 32-bit driver in addition to the 64-bit driver.
      '';
    };
  };

  config = let
    mesa-drivers = [ pkgs.mesa.drivers ]
      ++ lib.optional cfg.enable32bits pkgs.pkgsi686Linux.mesa.drivers;
    intel-driver = [ pkgs.intel-media-driver pkgs.vaapiIntel ]
      ++ lib.optionals cfg.enable32bits [ pkgs.pkgsi686Linux.intel-media-driver pkgs.driversi686Linux.vaapiIntel ];
    libvdpau = [ pkgs.libvdpau-va-gl ]
      ++ lib.optional cfg.enable32bits pkgs.pkgsi686Linux.libvdpau-va-gl;
    glxindirect = pkgs.runCommand "mesa_glxindirect" { } (''
      mkdir -p "$out"/lib
      ln -s ${pkgs.mesa.drivers}/lib/libGLX_mesa.so.0 "$out"/lib/libGLX_indirect.so.0
    '');
    LIBGL_DRIVERS_PATH = lib.makeSearchPathOutput "lib" "lib/dri" mesa-drivers;
    LIBVA_DRIVERS_PATH = lib.makeSearchPathOutput "out" "lib/dri" intel-driver;
    ldLibraryPaths = [
      (lib.makeLibraryPath mesa-drivers)
      (lib.makeSearchPathOutput "lib" "lib/vdpau" libvdpau)
      glxindirect
      "$LD_LIBRARY_PATH"
    ];
    LD_LIBRARY_PATH = lib.concatStringsSep ":" ldLibraryPaths;
  in mkIf cfg.enable {
    home.programs.zsh.sessionVariables = {
      inherit LIBGL_DRIVERS_PATH LIBVA_DRIVERS_PATH LD_LIBRARY_PATH;
    };
  };
}
