{
  description = "Micro Magic CAD — reproducible Nix FHS environment (Nix X server)";

  nixConfig = {
    extra-experimental-features = "nix-command flakes";
  };

  inputs = {
    # NixOS 25.05 (Warbler). flake.lock records rev + narHash (durable GitHub commit).
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
  };

  outputs =
    {
      self,
      nixpkgs,
    }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = false;
      };
      inherit (pkgs) lib;

      # GCC stamps __DATE__/__TIME__ from this epoch (do not pass -D__DATE__;
      # the space-padded day breaks the cc-wrapper). Also used for ar/tar.
      sourceDateEpoch = "315532800";

      vendorSrc =
        if !builtins.pathExists ./vendor/mmi/src/max4.3.16 then
          throw "vendor/mmi/src/max4.3.16 missing — this git tree must include the public-domain CAD sources"
        else
          lib.fileset.toSource {
            root = ./vendor/mmi;
            fileset = lib.fileset.difference ./vendor/mmi (
              lib.fileset.unions (
                lib.optional (builtins.pathExists ./vendor/mmi/bin) ./vendor/mmi/bin
              )
            );
          };

      xkbRoot =
        if builtins.pathExists "${pkgs.xkeyboard_config}/etc/X11/xkb" then
          "${pkgs.xkeyboard_config}/etc/X11/xkb"
        else
          "${pkgs.xkeyboard_config}/share/X11/xkb";

      mmiFonts = pkgs.runCommand "mmi-xfonts" {
        SOURCE_DATE_EPOCH = sourceDateEpoch;
        TZ = "UTC";
        LC_ALL = "C";
        nativeBuildInputs = [
          pkgs.xorg.mkfontscale
          pkgs.xorg.mkfontdir
          pkgs.findutils
          pkgs.coreutils
          pkgs.gawk
          pkgs.gzip
        ];
        # Bitmap fonts only. BH Lucida and IBM Type1 are unfreeRedistributable
        # in nixpkgs 25.05; keep allowUnfree = false.
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
          pkgs.xorg.encodings
        ];
      } ''
        export LC_ALL=C
        mkdir -p $out
        for pkg in $fontPkgs; do
          find "$pkg" -type d \( \
              -name 75dpi -o -name 100dpi -o -name misc \
              -o -name Type1 -o -name cyrillic -o -name encodings \
            \) 2>/dev/null | LC_ALL=C sort | while read -r d; do
            base="$(basename "$d")"
            mkdir -p "$out/$base"
            find "$d" -maxdepth 1 -type f \
              ! -name fonts.dir ! -name fonts.scale \
              | LC_ALL=C sort \
              | while read -r f; do
                  cp -f "$f" "$out/$base"/
                done
          done
        done
        chmod -R u+w "$out"
        find "$out" -name '*.pcf.gz' -print0 | LC_ALL=C sort -z | xargs -0 -r gzip -df
        for dir in $out/misc $out/75dpi $out/100dpi; do
          mkdir -p "$dir"
          {
            [ -f "$dir/fonts.alias" ] && cat "$dir/fonts.alias"
            cat ${./nix/x11/fonts.alias}
          } > "$dir/fonts.alias.new"
          mv "$dir/fonts.alias.new" "$dir/fonts.alias"
        done
        for dir in $out/misc $out/75dpi $out/100dpi; do
          if [ -d "$dir" ]; then
            rm -f "$dir/fonts.dir" "$dir/fonts.scale"
            (cd "$dir" && mkfontdir . && mkfontscale .)
            bash ${./nix/x11/sort-font-index.sh} "$dir"
            if [ -f "$dir/fonts.dir" ]; then
              awk -f ${./nix/x11/mk-font-aliases.awk} "$dir/fonts.dir" >> "$dir/fonts.alias"
            fi
          fi
        done
        for dir in $out/Type1 $out/cyrillic; do
          if [ -d "$dir" ]; then
            rm -f "$dir/fonts.dir" "$dir/fonts.scale"
            (cd "$dir" && mkfontdir .)
            bash ${./nix/x11/sort-font-index.sh} "$dir"
          fi
        done
        chmod -R u+w "$out"
      '';

      # Scripts + Magic rc fallbacks + samples only. Foundry PDKs are not
      # flake inputs; MAX File → Import PDK downloads them at user request.
      # Copy via fileset from the flake root so nested git-tracked paths
      # (pdk/samples, pdk/magic) are included. A direct directory import of
      # pdk on a dirty tree can snapshot only top-level files.
      mmiPdk = pkgs.runCommand "mmi-pdk"
        {
          SOURCE_DATE_EPOCH = sourceDateEpoch;
          TZ = "UTC";
          LC_ALL = "C";
          src = lib.fileset.toSource {
            root = ./.;
            fileset = ./pdk;
          };
          xresources = ./nix/x11/Xresources;
          appDefaults = ./nix/x11/app-defaults-Mmi;
        }
        ''
          export LC_ALL=C
          mkdir -p $out/app-defaults $out/magic $out/samples
          install -Dm644 "$src/pdk/pdk_import.tcl" $out/pdk_import.tcl
          install -Dm644 "$src/pdk/mag_import.tcl" $out/mag_import.tcl
          install -Dm755 "$src/pdk/mag2gds.sh" $out/mag2gds.sh
          install -Dm755 "$src/pdk/fetch_pdk.sh" $out/fetch_pdk.sh
          install -Dm644 "$src/pdk/maxrc" $out/maxrc
          if [ -d "$src/pdk/samples" ]; then
            cp -a "$src/pdk/samples/." $out/samples/
          fi
          if [ -d "$src/pdk/magic" ]; then
            cp -a "$src/pdk/magic/." $out/magic/
          fi
          chmod -R u+w "$out"
          install -Dm644 "$xresources" $out/Xresources
          install -Dm644 "$appDefaults" $out/app-defaults/Mmi
        '';

      # Import each header as a file path. A dirty flake cannot import the
      # pccts-h directory itself (Git tracks files, not directories).
      pcctsH = pkgs.runCommand "mmi-pccts-h" { } ''
        mkdir -p $out
        cp ${./nix/rebuild/pccts-h/antlr.h} $out/antlr.h
        cp ${./nix/rebuild/pccts-h/config.h} $out/config.h
        cp ${./nix/rebuild/pccts-h/dlgauto.h} $out/dlgauto.h
        cp ${./nix/rebuild/pccts-h/dlgdef.h} $out/dlgdef.h
        cp ${./nix/rebuild/pccts-h/err.h} $out/err.h
        cp ${./nix/rebuild/pccts-h/int.h} $out/int.h
        cp ${./nix/rebuild/pccts-h/pccts_stdarg.h} $out/pccts_stdarg.h
        cp ${./nix/rebuild/pccts-h/pccts_stdio.h} $out/pccts_stdio.h
        cp ${./nix/rebuild/pccts-h/pccts_stdlib.h} $out/pccts_stdlib.h
        cp ${./nix/rebuild/pccts-h/pccts_string.h} $out/pccts_string.h
        cp ${./nix/rebuild/pccts-h/pcctscfg.h} $out/pcctscfg.h
        cp ${./nix/rebuild/pccts-h/set.h} $out/set.h
      '';

      mmiVendor = pkgs.stdenv.mkDerivation {
        pname = "mmi-vendor";
        version = "040526-x86_64";
        src = vendorSrc;
        PATCH_INTPTR = ./nix/rebuild/patch-intptr.py;
        PATCH_PCCTS_H = pcctsH;
        nativeBuildInputs = [
          pkgs.gnumake
          pkgs.python3
          pkgs.file
          pkgs.gawk
          pkgs.gnused
          pkgs.gnugrep
          pkgs.findutils
          pkgs.bash
          pkgs.binutils
          pkgs.gnum4
          pkgs.tcl
          pkgs.gnutar
          pkgs.gzip
          pkgs.xorg.mkfontscale
          pkgs.xorg.mkfontdir
        ];
        buildInputs = with pkgs; [
          xorg.libX11
          xorg.libXext
          xorg.libXt
          xorg.libXmu
          xorg.libXpm
          xorg.libXaw
          xorg.libICE
          xorg.libSM
          xorg.xorgproto
          xorg.libXi
          xorg.libXrender
        ];
        dontConfigure = true;
        dontUpdateAutotoolsGnuConfigScripts = true;
        dontCheckForBrokenSymlinks = true;
        enableParallelBuilding = false;
        strictDeps = true;
        SOURCE_DATE_EPOCH = sourceDateEpoch;
        TZ = "UTC";
        LC_ALL = "C";
        LANG = "C";
        hardeningDisable = [
          "format"
          "fortify"
          "fortify3"
          "stackprotector"
          "pic"
          "strictoverflow"
        ];
        NIX_CFLAGS_COMPILE = "-std=gnu89 -fcommon -fno-strict-aliasing -frandom-seed=mmi-cad-040526 -U_FORTIFY_SOURCE -D_FORTIFY_SOURCE=0 -fpermissive -Wno-error -Wno-implicit-function-declaration -Wno-implicit-int -Wno-int-conversion -Wno-incompatible-pointer-types -Wno-pointer-to-int-cast -Wno-int-to-pointer-cast -Wno-return-type -Wno-unused -Wno-builtin-declaration-mismatch -Wno-endif-labels -include float.h -DCLK_TCK=100 -DUSE_SYSTEM_MALLOC";
        postPatch = ''
          export PATCH_INTPTR="$PATCH_INTPTR"
          export PATCH_PCCTS_H="$PATCH_PCCTS_H"
          bash ${./nix/rebuild/patch-source.sh} "$PWD"
        '';
        buildPhase = ''
          bash ${./nix/rebuild/build.sh}
        '';
        installPhase = ''
          export LAYOUT_SH="${./nix/rebuild/layout.sh}"
          export SORT_FONT_INDEX_SH="${./nix/x11/sort-font-index.sh}"
          bash ${./nix/rebuild/install.sh} "$PWD" "$out"
        '';
        meta = {
          description = "Micro Magic CAD rebuilt as ELF 64-bit from public-domain sources";
          platforms = [ "x86_64-linux" ];
        };
      };

      cshCompat = pkgs.runCommand "csh-compat" { } ''
        mkdir -p $out/bin
        ln -s ${pkgs.tcsh}/bin/tcsh $out/bin/csh
      '';

      mmiCad = pkgs.buildFHSEnv {
        pname = "mmi-cad";
        version = "1.0.0";

        extraBuildCommands = ''
          mkdir -p $out/mmi-home/work
          mkdir -p $out/mmi-pdks
          mkdir -p $out/mmi-bundle
          mkdir -p $out/mmi-magic
          mkdir -p $out/mmi-vendor
          mkdir -p $out/mmi-xfonts
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
            zstd
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
            xorg.mkfontscale
            fontconfig
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
            expat
            zlib
            ncurses
            libpng
            libjpeg
            libtiff
            openssl
            stdenv.cc.cc.lib
            tigervnc
            novnc
            python3Packages.websockify
            xorg.xkbcomp
            xorg.xsetroot
            xkeyboard_config
            gyre-fonts
            psutils
          ]);

        extraPreBwrapCmds = ''
          if [ -z "''${MMI_CAD_ROOT:-}" ]; then
            if [ -d "$PWD/vendor/mmi/src/max4.3.16" ] && [ -w "$PWD" ]; then
              export MMI_CAD_ROOT="$PWD"
            else
              export MMI_CAD_ROOT="''${XDG_STATE_HOME:-$HOME/.local/state}/mmi-cad"
            fi
          fi
          mkdir -p \
            "$MMI_CAD_ROOT/data/pdks" \
            "$MMI_CAD_ROOT/data/workspace" \
            "$MMI_CAD_ROOT/data/home" \
            "$MMI_CAD_ROOT/data/fonts/max"
        '';

        extraBwrapArgs = [
          "--bind \"$MMI_CAD_ROOT/data/home\" /mmi-home"
          "--bind \"$MMI_CAD_ROOT/data/workspace\" /mmi-home/work"
          "--bind \"$MMI_CAD_ROOT/data/pdks\" /mmi-pdks"
          "--bind-try /tmp/.X11-unix /tmp/.X11-unix"
          "--ro-bind-try \"$HOME/.Xauthority\" \"$HOME/.Xauthority\""
          "--ro-bind-try ${mmiVendor} /mmi-vendor"
          "--ro-bind-try ${mmiPdk} /mmi-bundle"
          "--ro-bind-try ${pkgs.magic-vlsi} /mmi-magic"
          "--ro-bind-try ${mmiFonts} /mmi-xfonts"
        ];

        profile = ''
          export MMI_FONTS_SRC=${mmiFonts}
          export MMI_PDK_DIR=/mmi-bundle
          export MMI_TOOLS=/mmi-vendor/mmi
          export MMI_LOCAL=/mmi-home/cad/mmi_local
          export MMI_FONT_CACHE="''${MMI_FONT_CACHE:-''${MMI_CAD_ROOT}/data/fonts/max}"
          export PDK_ROOT="''${PDK_ROOT:-/mmi-pdks}"
          export PDK="''${PDK:-sky130A}"
          export MMI_XKB_ROOT=${xkbRoot}
          export QT_X11_NO_MITSHM=1
          export LC_ALL=C
          export LANG=C
          export TZ=UTC
          export _XNO_XFT=1
          export SSL_CERT_FILE=${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt
          export NIX_SSL_CERT_FILE=$SSL_CERT_FILE
        '';

        runScript = pkgs.writeShellScript "mmi-cad-launch" (
          (builtins.readFile ./nix/x11/start-display.sh)
          + "\n"
          + (builtins.readFile ./nix/launch.sh)
        );

        meta = {
          description = "Micro Magic CAD FHS wrapper (x86_64 Linux: bare metal, VM, WSL2)";
          platforms = [ "x86_64-linux" ];
        };
      };

      requiredBinsCheck = pkgs.runCommand "mmi-vendor-required-bins" {
        nativeBuildInputs = [ pkgs.file ];
      } ''
        set -euo pipefail
        bin="${mmiVendor}/mmi/bin"
        for b in max.bin sue.exe nst sue_tee ext2spice ext2sim gemini irsim anXhelper edif2sue make_tech max sue; do
          if [ ! -e "$bin/$b" ]; then
            echo "missing $bin/$b" >&2
            ls -la "$bin" >&2 || true
            exit 1
          fi
        done
        for b in max.bin sue.exe nst sue_tee ext2spice ext2sim gemini irsim anXhelper edif2sue; do
          file -L "$bin/$b" | grep -q 'ELF 64-bit' || {
            echo "not ELF 64-bit: $b" >&2
            file -L "$bin/$b" >&2
            exit 1
          }
        done
        touch $out
      '';
    in
    {
      packages.${system} = {
        default = mmiCad;
        mmi-cad = mmiCad;
        mmi-vendor = mmiVendor;
        mmi-xfonts = mmiFonts;
        mmi-pdk = mmiPdk;
      };

      apps.${system}.default = {
        type = "app";
        program = "${mmiCad}/bin/mmi-cad";
      };

      checks.${system} = {
        mmi-vendor-required-bins = requiredBinsCheck;
      };

      devShells.${system}.default = pkgs.mkShell {
        packages = [
          mmiCad
          pkgs.git
        ];
        shellHook = ''
          echo "Micro Magic CAD — NixOS 25.05 FHS (x86_64 Linux: bare metal / VM / WSL2)"
          echo "  nix run .#mmi-cad          # CAD shell (Nix Xvnc + noVNC)"
          echo "  nix run .#mmi-cad -- max   # start MAX"
          export MMI_CAD_ROOT="''${MMI_CAD_ROOT:-$PWD}"
        '';
      };
    };
}
