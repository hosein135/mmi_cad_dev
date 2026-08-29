{
  description = "Micro Magic CAD — Nix FHS environment (no Docker)";

  # Tarball fetch (not a full git clone) so first-time `nix flake lock` stays practical.
  inputs.nixpkgs.url = "https://github.com/NixOS/nixpkgs/archive/nixos-unstable.tar.gz";

  outputs =
    { self, nixpkgs }:
    let
      system = "x86_64-linux";

      pkgs = import nixpkgs {
        inherit system;
        config = {
          allowUnfree = true;
          permittedInsecurePackages = [
            "openssl-1.1.1w"
            "openssl-1.1.1v"
            "openssl-1.1.1u"
          ];
        };
      };

      inherit (pkgs) lib;

      # Combined XLFD bitmap fonts for Motif (max/nst). Copied to .mmi-xfonts at runtime
      # so the host X server (including VcXsrv on WSL) can open the files.
      mmiFonts = pkgs.runCommand "mmi-xfonts" {
        nativeBuildInputs = [
          pkgs.xorg.mkfontdir
          pkgs.xorg.mkfontscale
          pkgs.findutils
          pkgs.coreutils
        ];
        fontPkgs = [
          pkgs.xorg.fontadobe75dpi
          pkgs.xorg.fontadobe100dpi
          pkgs.xorg.fontmiscmisc
          pkgs.xorg.fontcursormisc
          pkgs.xorg.fontbitstream75dpi
          pkgs.xorg.fontbitstream100dpi
          pkgs.xorg.fontalias
          pkgs.xorg.fontmisccyrillic
          pkgs.xorg.fontcronyxcyrillic
          pkgs.xorg.fontbh75dpi
          pkgs.xorg.fontbh100dpi
          pkgs.xorg.fontbhtype1
          pkgs.xorg.fontbitstreamtype1
          pkgs.xorg.fontibmtype1
          pkgs.xorg.encodings
        ];
      } ''
        mkdir -p $out
        for pkg in $fontPkgs; do
          find "$pkg" -type d \( \
              -name 75dpi -o -name 100dpi -o -name misc \
              -o -name Type1 -o -name cyrillic -o -name encodings \
            \) 2>/dev/null | while read -r d; do
            base="$(basename "$d")"
            mkdir -p "$out/$base"
            cp -a "$d"/. "$out/$base"/ || true
          done
        done
        mkdir -p $out/misc $out/75dpi $out/100dpi
        cp ${./nix/fonts.alias} $out/misc/fonts.alias
        cp ${./nix/fonts.alias} $out/75dpi/fonts.alias
        cp ${./nix/fonts.alias} $out/100dpi/fonts.alias
        for dir in $out/misc $out/75dpi $out/100dpi $out/Type1 $out/cyrillic; do
          if [ -d "$dir" ]; then
            (cd "$dir" && mkfontdir . && mkfontscale . 2>/dev/null || true)
          fi
        done
      '';

      mmiPdk = pkgs.runCommand "mmi-pdk" { } ''
        mkdir -p $out/app-defaults $out/samples
        cp ${./max_pdk/pdk_import.tcl} $out/
        cp ${./max_pdk/mag_import.tcl} $out/
        cp ${./max_pdk/mag2gds.sh} $out/
        cp ${./max_pdk/maxrc} $out/
        chmod +x $out/mag2gds.sh
        cp ${./nix/Xresources} $out/Xresources
        cp ${./nix/app-defaults-Mmi} $out/app-defaults/Mmi
        cp -a ${./max_pdk/samples}/. $out/samples/
      '';

      cshCompat = pkgs.runCommand "csh-compat" { } ''
        mkdir -p $out/bin
        ln -s ${pkgs.tcsh}/bin/tcsh $out/bin/csh
      '';

      # 32-bit Motif CAD + 64-bit Magic and CLI tools, FHS layout (/lib, /usr, /bin).
      mmiCad = pkgs.buildFHSEnv {
        pname = "mmi-cad";
        version = "1.0.0";

        targetPkgs =
          p:
          [
            cshCompat
          ]
          ++ (with p; [
            bashInteractive
            coreutils
            findutils
            gnugrep
            gnused
            gawk
            gnutar
            gzip
            bzip2
            xz
            unzip
            file
            which
            less
            procps
            iproute2
            inetutils
            curl
            wget
            git
            cacert
            gnumake
            diffutils
            patch
            perl
            tcl
            tk
            tcsh
            xterm
            xdg-utils
            strace
            magic-vlsi
            xorg.xset
            xorg.xlsfonts
            xorg.xrdb
            xorg.xauth
            xorg.xhost
            xorg.mkfontdir
            xorg.mkfontscale
            fontconfig
          ])
          ++ lib.optionals (p ? urw-base35-fonts) [ p.urw-base35-fonts ];

        # Installed for both i686 and x86_64 so the 2004 i486 binaries can resolve
        # libX11/Motif/glibc. OpenSSL 3 replaces Ubuntu 20.04's 1.1; 1.1 is added
        # when nixpkgs still provides it. libstdc++.so.5 is for pre-GCC4 binaries.
        multiPkgs =
          p:
          with p;
          [
            glibc
            libxcrypt
            libGL
            libGLU
            xorg.libX11
            xorg.libXext
            xorg.libXt
            xorg.libXmu
            xorg.libXpm
            xorg.libXaw
            xorg.libICE
            xorg.libSM
            xorg.libXrender
            xorg.libXcursor
            xorg.libXi
            xorg.libXrandr
            xorg.libXinerama
            xorg.libXfixes
            xorg.libXft
            xorg.libXxf86vm
            xorg.libxcb
            xorg.libXau
            xorg.libXdmcp
            freetype
            fontconfig
            expat
            zlib
            bzip2
            ncurses
            libpng
            libjpeg
            libtiff
            openssl
            krb5
            keyutils
            libbsd
            libidn2
            libunistring
            gpm
            motif
            stdenv.cc.cc.lib
          ]
          ++ lib.optionals (p ? ncurses5) [ p.ncurses5 ]
          ++ lib.optionals (p ? libstdcxx5) [ p.libstdcxx5 ]
          ++ lib.optionals (p ? openssl_1_1) [ p.openssl_1_1 ]
          ++ lib.optionals (p ? libnsl) [ p.libnsl ]
          ++ lib.optionals (p.xorg ? libXp) [ p.xorg.libXp ]
          ++ lib.optionals (p ? libxp) [ p.libxp ];

        extraPreBwrapCmds = ''
          if [ -z "''${MMI_CAD_ROOT:-}" ]; then
            export MMI_CAD_ROOT="$PWD"
          fi
          mkdir -p \
            "$MMI_CAD_ROOT/pdks" \
            "$MMI_CAD_ROOT/workspace" \
            "$MMI_CAD_ROOT/.mmi-prefix/home"
        '';

        extraBwrapArgs = [
          "--bind-try \"$MMI_CAD_ROOT/.mmi-prefix/home\" /home/caduser"
          "--bind-try \"$MMI_CAD_ROOT/workspace\" /home/caduser/work"
          "--bind-try \"$MMI_CAD_ROOT/pdks\" /opt/pdks"
          "--ro-bind-try ${mmiPdk} /opt/mmi-pdk"
          "--ro-bind-try ${pkgs.magic-vlsi} /opt/magic"
        ];

        profile = ''
          export MMI_FONTS_SRC=${mmiFonts}
          export MMI_PDK_DIR=/opt/mmi-pdk
          export PDK_ROOT="''${PDK_ROOT:-/opt/pdks}"
          export PDK="''${PDK:-sky130A}"
          export QT_X11_NO_MITSHM=1
          export LC_ALL=C
          export LANG=C
          export _XNO_XFT=1
          export SSL_CERT_FILE=${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt
          export NIX_SSL_CERT_FILE=$SSL_CERT_FILE
        '';

        runScript = pkgs.writeShellScript "mmi-cad-launch" (
          builtins.readFile ./nix/mmi-launch.sh
        );

        meta = {
          description = "Micro Magic CAD FHS wrapper (32-bit Motif tools + Magic VLSI)";
          platforms = [ "x86_64-linux" ];
        };
      };
    in
    {
      packages.${system} = {
        default = mmiCad;
        mmi-cad = mmiCad;
        mmi-xfonts = mmiFonts;
        mmi-pdk = mmiPdk;
      };

      apps.${system}.default = {
        type = "app";
        program = "${mmiCad}/bin/mmi-cad";
      };

      devShells.${system}.default = pkgs.mkShell {
        packages = [
          mmiCad
          pkgs.curl
          pkgs.git
        ];
        shellHook = ''
          echo "Micro Magic CAD — Nix FHS (no Docker)"
          echo "  mmi-cad          # CAD shell"
          echo "  mmi-cad max      # start MAX"
          echo "Set MMI_CAD_ROOT if you are not in the project directory."
          export MMI_CAD_ROOT="''${MMI_CAD_ROOT:-$PWD}"
        '';
      };

    };
}
