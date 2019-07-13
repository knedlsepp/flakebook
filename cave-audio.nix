{ config, pkgs, ... }:

let
  caveAudioFiles = pkgs.fetchzip {
    url = "https://github.com/nebulakl/cave-audio/archive/0ac059e243c8663908500ec01d7a11ee116041d9.tar.gz";
    sha256 = "0c9bdj96d3d12fyiyh3fiim47b1lhsw1pbqb52ny0sp5wh64dwl5";
  };
  crosAudioTopology = pkgs.fetchurl {
    url = "https://bugzilla.kernel.org/attachment.cgi?id=282677";
    sha256 = "0n3ycx91g98pdias9594jqllvjxwh7ib0w65gpk5siayldqxgaal";
  };
in
{
  # Required for screen brightness control:
  boot.kernelParams = [ "acpi_backlight=vendor" ];

  services.acpid.enable = true;

  hardware.enableRedistributableFirmware = true;
  hardware.firmware = [
    (pkgs.runCommandNoCC "firmware-audio-CAVE" {} ''
      mkdir -p $out/lib/firmware
      cp ${crosAudioTopology} $out/lib/firmware/9d70-CORE-COREBOOT-0-tplg.bin
    '')
  ];
  boot.kernelModules = [ "skl_n88l25_m98357a" "snd_soc_skl" ];

  # Sound requires custom UCM files and topology bin:
  system.replaceRuntimeDependencies = [
    {
      original = pkgs.alsaLib;
      replacement = pkgs.alsaLib.overrideAttrs (super: {
        postFixup = ''
          cp -r ${caveAudioFiles}/Google-Cave-1.0-Cave $out/share/alsa/ucm/
          ln -s $out/share/alsa/ucm/Google-Cave-1.0-Cave/ $out/share/alsa/ucm/sklnau8825max
        '';
      });
    }
    {
      original = pkgs.firmwareLinuxNonfree;
      replacement = pkgs.firmwareLinuxNonfree.overrideAttrs (super: {
        postInstall = ''
          cd $out/lib/firmware/intel/
          rm dsp_fw_release.bin
          ln -s dsp_fw_release_v969.bin dsp_fw_release.bin
        '';
      });
    }
  ];
}