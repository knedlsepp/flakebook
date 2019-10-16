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
  services.acpid.logEvents = true;
  services.acpid.handlers = let
    pactlCMD = ''
      function pactl_set_card_profile() {
        pid=$(${pkgs.procps}/bin/pidof pulseaudio)
        user=$(${pkgs.coreutils}/bin/stat -c '%U' /proc/"$pid")
        uid=$(${pkgs.coreutils}/bin/stat -c '%u' /proc/"$pid")
        export PULSE_RUNTIME_PATH="/run/user/$uid/pulse"
        ${pkgs.shadow.su}/bin/su --preserve-environment -c "${pkgs.pulseaudioFull}/bin/pactl set-card-profile 0 $1" "$user"
      }
    '';
  in {
    headphonesEnabled = {
      event = "jack/headphone HEADPHONE plug";
      action = ''
        ${pactlCMD}
        pactl_set_card_profile Headphone
      '';
    };
    speakersEnabled = {
      event = "jack/headphone HEADPHONE unplug";
      action = ''
        ${pactlCMD}
        pactl_set_card_profile Speaker
      '';
    };
  };


  hardware.enableRedistributableFirmware = true;
  hardware.firmware = [
    (pkgs.runCommandNoCC "firmware-audio-CAVE" {} ''
      mkdir -p $out/lib/firmware
      cp ${crosAudioTopology} $out/lib/firmware/9d70-CORE-COREBOOT-0-tplg.bin
      cp ${crosAudioTopology} $out/lib/firmware/dfw_sst.bin
    '')
    (pkgs.runCommandNoCC "firmware-audio-CAVE" {} ''
      mkdir -p $out/lib/firmware/intel/
      ln -s ${pkgs.firmwareLinuxNonfree}/lib/firmware/intel/dsp_fw_release_v969.bin $out/lib/firmware/intel/dsp_fw_release.bin
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
    # {
    #   original = pkgs.firmwareLinuxNonfree;
    #   replacement = pkgs.firmwareLinuxNonfree.overrideAttrs (super: {
    #     postInstall = ''
    #       cd $out/lib/firmware/intel/
    #       rm dsp_fw_release.bin
    #       ln -s dsp_fw_release_v969.bin dsp_fw_release.bin
    #     '';
    #   });
    # }
  ];
}

