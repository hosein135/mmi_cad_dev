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
        config.allowUnfree = true;
      };

      inherit (pkgs) lib;

      # Combined XLFD bitmap fonts for Motif (max/nst). Copied to .mmi-xfonts at runtime
      # so the host X server (including VcXsrv on WSL) can open the files.
      mmiFonts = pkgs.runCommand "mmi-xfonts" {
        nativeBuildInputs = [
          pkgs.mkfontscale
          pkgs.findutils
          pkgs.coreutils
        ];
        fontPkgs = [
          pkgs.font-adobe-75dpi
          pkgs.font-adobe-100dpi
          pkgs.font-misc-misc
          pkgs.font-cursor-misc
          pkgs.font-bitstream-75dpi
          pkgs.font-bitstream-100dpi
          pkgs.font-alias
          pkgs.font-misc-cyrillic
          pkgs.font-cronyx-cyrillic
          pkgs.font-bh-75dpi
          pkgs.font-bh-100dpi
          pkgs.font-bh-type1
          pkgs.font-bitstream-type1
          pkgs.font-ibm-type1
          pkgs.font-encodings
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
            find "$d" -maxdepth 1 -type f \
              ! -name fonts.dir ! -name fonts.scale ! -name fonts.alias \
              -exec cp -f {} "$out/$base"/ \;
          done
        done
        chmod -R u+w "$out"
        install -Dm644 ${./nix/fonts.alias} $out/misc/fonts.alias
        install -Dm644 ${./nix/fonts.alias} $out/75dpi/fonts.alias
        install -Dm644 ${./nix/fonts.alias} $out/100dpi/fonts.alias
        for dir in $out/misc $out/75dpi $out/100dpi $out/Type1 $out/cyrillic; do
          if [ -d "$dir" ]; then
            rm -f "$dir/fonts.dir" "$dir/fonts.scale"
            (cd "$dir" && mkfontdir . && mkfontscale . 2>/dev/null || true)
          fi
        done
        chmod -R u+w "$out"
      '';

      mmiPdk = pkgs.runCommand "mmi-pdk"
        {
          src = ./max_pdk;
          xresources = ./nix/Xresources;
          appDefaults = ./nix/app-defaults-Mmi;
        }
        ''
          mkdir -p $out/app-defaults
          install -Dm644 "$src/pdk_import.tcl" $out/pdk_import.tcl
          install -Dm644 "$src/mag_import.tcl" $out/mag_import.tcl
          install -Dm755 "$src/mag2gds.sh" $out/mag2gds.sh
          install -Dm644 "$src/maxrc" $out/maxrc
          cp -r "$src/samples" $out/
          chmod -R u+w "$out"
          install -Dm644 "$xresources" $out/Xresources
          install -Dm644 "$appDefaults" $out/app-defaults/Mmi
        '';

      cshCompat = pkgs.runCommand "csh-compat" { } ''
        mkdir -p $out/bin
        ln -s ${pkgs.tcsh}/bin/tcsh $out/bin/csh
      '';

      # 32-bit Motif CAD + 64-bit Magic and CLI tools, FHS layout (/lib, /usr, /bin).
      mmiCad = pkgs.buildFHSEnv {
        pname = "mmi-cad";
        version = "1.0.0";

        # Mount points inside the FHS root (not host /home — bwrap cannot mkdir there).
        extraBuildCommands = ''
          mkdir -p $out/mmi-home/work
          mkdir -p $out/mmi-pdks
        '';

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
            xset
            xlsfonts
            xrdb
            xauth
            xhost
            mkfontscale
            fontconfig
          ])
          ++ lib.optionals (p ? urw-base35-fonts) [ p.urw-base35-fonts ];

        # Installed for both i686 and x86_64 so the 2004 i486 binaries can resolve
        # libX11/Motif/glibc. OpenSSL 3 only (1.1 is EOL and removed from nixpkgs).
        multiPkgs =
          p:
          with p;
          [
            glibc
            libxcrypt
            libGL
            libGLU
            libx11
            libxext
            libxt
            libxmu
            libxpm
            libxaw
            libice
            libsm
            libxrender
            libxcursor
            libxi
            libxrandr
            libxinerama
            libxfixes
            libxft
            libxxf86vm
            libxcb
            libxau
            libxdmcp
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
          ++ lib.optionals (p ? libnsl) [ p.libnsl ]
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
          "--bind \"$MMI_CAD_ROOT/.mmi-prefix/home\" /mmi-home"
          "--bind \"$MMI_CAD_ROOT/workspace\" /mmi-home/work"
          "--bind \"$MMI_CAD_ROOT/pdks\" /mmi-pdks"
          "--ro-bind-try ${mmiPdk} /opt/mmi-pdk"
          "--ro-bind-try ${pkgs.magic-vlsi} /opt/magic"
        ];

        profile = ''
          export MMI_FONTS_SRC=${mmiFonts}
          export MMI_PDK_DIR=/opt/mmi-pdk
          export PDK_ROOT="''${PDK_ROOT:-/mmi-pdks}"
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
