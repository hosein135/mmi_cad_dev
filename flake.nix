{
  description = "Micro Magic CAD — Nix FHS environment (no Docker)";

  nixConfig.extra-experimental-features = "nix-command flakes";

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

      pwd = builtins.getEnv "PWD";

      vendorSrc =
        let
          hasSrc = p: builtins.pathExists (p + "/src/max4.3.16");
          dirCands =
            lib.filter (p: p != null) (
              [ ./vendor/mmi ]
              ++ lib.optionals (pwd != "") [ (/. + "${pwd}/vendor/mmi") ]
            );
          tarCands =
            lib.filter (p: p != null) (
              [
                ./vendor/mmi_pd_040526.tar.gz
                ./vendor/mmi_pd_040526.tar
              ]
              ++ lib.optionals (pwd != "") [
                (/. + "${pwd}/vendor/mmi_pd_040526.tar.gz")
                (/. + "${pwd}/vendor/mmi_pd_040526.tar")
              ]
            );
          fromDir = lib.findFirst hasSrc null dirCands;
          fromTar = lib.findFirst builtins.pathExists null tarCands;
        in
        if fromDir != null then fromDir else fromTar;

      vendorIsTarball =
        vendorSrc != null
        && (
          lib.hasSuffix ".tar.gz" (toString vendorSrc) || lib.hasSuffix ".tar" (toString vendorSrc)
        );

      mmiFonts = pkgs.runCommand "mmi-xfonts" {
        nativeBuildInputs = [
          pkgs.mkfontscale
          pkgs.findutils
          pkgs.coreutils
          pkgs.gawk
          pkgs.gzip
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
              ! -name fonts.dir ! -name fonts.scale \
              -exec cp -f {} "$out/$base"/ \;
          done
        done
        chmod -R u+w "$out"
        # Some X servers will not list or load gzipped PCFs.
        find "$out" -name '*.pcf.gz' -exec gzip -df {} + 2>/dev/null || true
        for dir in $out/misc $out/75dpi $out/100dpi; do
          mkdir -p "$dir"
          {
            [ -f "$dir/fonts.alias" ] && cat "$dir/fonts.alias"
            cat ${./nix/x11/fonts.alias}
          } > "$dir/fonts.alias.new"
          mv "$dir/fonts.alias.new" "$dir/fonts.alias"
        done
        for dir in $out/misc $out/75dpi $out/100dpi $out/Type1 $out/cyrillic; do
          if [ -d "$dir" ]; then
            rm -f "$dir/fonts.dir" "$dir/fonts.scale"
            (cd "$dir" && mkfontdir . && mkfontscale . 2>/dev/null || true)
            if [ -f "$dir/fonts.dir" ]; then
              awk -f ${./nix/x11/mk-font-aliases.awk} "$dir/fonts.dir" >> "$dir/fonts.alias"
            fi
          fi
        done
        chmod -R u+w "$out"
      '';

      mmiPdk = pkgs.runCommand "mmi-pdk"
        {
          src = ./pdk;
          xresources = ./nix/x11/Xresources;
          appDefaults = ./nix/x11/app-defaults-Mmi;
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

      mmiVendor =
        if vendorSrc == null then
          pkgs.runCommand "mmi-vendor-missing" { } ''
            cat >&2 <<'EOF'
            mmi-vendor: extract the public-domain archive once:
              vendor/mmi_pd_040526.tar.gz
            then: ./run.sh --prep-only
            That unpacks to vendor/mmi (x86_64 layout) and deletes the tarball.
            EOF
            exit 1
          ''
        else
          pkgs.stdenv.mkDerivation (
            {
              pname = "mmi-vendor";
              version = "040526-x86_64";
              src = vendorSrc;
              PATCH_INTPTR = ./nix/rebuild/patch-intptr.py;
              PATCH_PCCTS_H = ./nix/rebuild/pccts-h;
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
              ];
              buildInputs = with pkgs; [
                libx11
                libxext
                libxt
                libxmu
                libxpm
                libxaw
                libice
                libsm
                xorgproto
                libxi
                libxrender
              ];
              dontConfigure = true;
              dontUpdateAutotoolsGnuConfigScripts = true;
              dontCheckForBrokenSymlinks = true;
              enableParallelBuilding = false;
              hardeningDisable = [
                "format"
                "fortify"
                "fortify3"
                "stackprotector"
                "pic"
                "strictoverflow"
              ];
              # Old C + modern GCC/glibc (FORTIFY aborts Tcl 8.0 / MAX).
              NIX_CFLAGS_COMPILE = "-std=gnu89 -fcommon -fno-strict-aliasing -U_FORTIFY_SOURCE -D_FORTIFY_SOURCE=0 -Wno-error -include float.h -DCLK_TCK=100";
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
                bash ${./nix/rebuild/install.sh} "$PWD" "$out"
              '';
              meta = {
                description = "Micro Magic CAD rebuilt as ELF 64-bit from public-domain sources";
                platforms = [ "x86_64-linux" ];
              };
            }
            // lib.optionalAttrs vendorIsTarball { sourceRoot = "mmi_pd_040526"; }
          );

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
            expat
            zlib
            ncurses
            libpng
            libjpeg
            libtiff
            openssl
            stdenv.cc.cc.lib
          ])
          ++ lib.optionals (p ? urw-base35-fonts) [ p.urw-base35-fonts ]
          ++ lib.optionals (p ? psutils) [ p.psutils ];

        extraPreBwrapCmds = ''
          if [ -z "''${MMI_CAD_ROOT:-}" ]; then
            export MMI_CAD_ROOT="$PWD"
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
          "--ro-bind-try ${mmiVendor} /mmi-vendor"
          "--ro-bind-try ${mmiPdk} /mmi-bundle"
          "--ro-bind-try ${pkgs.magic-vlsi} /mmi-magic"
        ];

        profile = ''
          export MMI_FONTS_SRC=${mmiFonts}
          export MMI_PDK_DIR=/mmi-bundle
          export MMI_TOOLS=/mmi-vendor/mmi
          export MMI_LOCAL=/mmi-home/cad/mmi_local
          # Default font mirror dir; override with MMI_MAX_FONTS_DIR or MMI_FONT_CACHE.
          export MMI_FONT_CACHE="''${MMI_FONT_CACHE:-''${MMI_CAD_ROOT}/data/fonts/max}"
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
          builtins.readFile ./nix/launch.sh
        );

        meta = {
          description = "Micro Magic CAD FHS wrapper (x86_64 rebuild from public-domain sources + Magic VLSI)";
          platforms = [ "x86_64-linux" ];
        };
      };
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

      devShells.${system}.default = pkgs.mkShell {
        packages = [
          mmiCad
          pkgs.curl
          pkgs.git
        ];
        shellHook = ''
          echo "Micro Magic CAD — Nix FHS"
          echo "  Vendor: x86_64 (rebuilt from src/)"
          echo "  mmi-cad          # CAD shell"
          echo "  mmi-cad max      # start MAX"
          export MMI_CAD_ROOT="''${MMI_CAD_ROOT:-$PWD}"
        '';
      };
    };
}
