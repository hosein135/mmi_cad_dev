# Dockerfile for Micro Magic CAD Installation
FROM ubuntu:20.04

ENV DEBIAN_FRONTEND=noninteractive

ARG MMI_TARBALL=mmi_pd_040526.tar.gz
ARG MMI_DIR=mmi_pd_040526

WORKDIR /install

COPY ${MMI_TARBALL} ./

# ── Step 1: Add 32-bit architecture and repositories ─────────────────────────
RUN dpkg --add-architecture i386 \
    && apt-get update \
    && apt-get install -y software-properties-common \
    && add-apt-repository universe \
    && add-apt-repository multiverse

# ── Step 2: Install runtime libs + legacy X11 bitmap fonts ───────────────────
# max/nst are Motif apps: XLFD fonts must be readable by the *host* X server.
# run.sh bind-mounts these fonts at the same absolute path on host + container.
RUN apt-get update && apt-get install -y --no-install-recommends \
    binutils:i386 libbinutils:i386 \
    gcc-9-base gcc-9-base:i386 \
    libc6:i386 libc6-i386 \
    libgcc-s1 libgcc-s1:i386 \
    libstdc++6 libstdc++6:i386 \
    libbsd0:i386 libcom-err2:i386 libcrypt1:i386 libgpm2:i386 \
    libidn2-0:i386 libncurses5:i386 libtinfo5:i386 \
    libssl-dev zlib1g zlib1g:i386 \
    krb5-locales libgssapi-krb5-2 libgssapi-krb5-2:i386 \
    libk5crypto3 libk5crypto3:i386 libkeyutils1:i386 \
    libkrb5-3 libkrb5-3:i386 libkrb5support0 libkrb5support0:i386 \
    x11-utils x11-xserver-utils xauth \
    libx11-6 libx11-6:i386 libx11-xcb1 libxau6:i386 libxcb1:i386 libxdmcp6:i386 \
    xfonts-base \
    xfonts-75dpi xfonts-100dpi \
    xfonts-75dpi-transcoded xfonts-100dpi-transcoded \
    xfonts-scalable xfonts-cyrillic xfonts-encodings \
    fonts-urw-base35 \
    fontconfig \
    csh zsh zsh-common xterm \
    sudo less iproute2 procps \
    wget curl unzip ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# ── Step 3: Enable bitmap fonts in fontconfig ────────────────────────────────
RUN rm -f /etc/fonts/conf.d/70-no-bitmaps.conf \
    && rm -f /etc/fonts/conf.d/30-no-embedded-bitmaps.conf \
    && ln -sf /usr/share/fontconfig/conf.avail/70-yes-bitmaps.conf /etc/fonts/conf.d/70-yes-bitmaps.conf

# ── Step 4: Font aliases for Motif apps that request Adobe XLFD names ─────────
# Prefer real adobe glyphs from xfonts-75dpi when present; aliases cover gaps.
RUN cat > /usr/share/fonts/X11/misc/fonts.alias << 'ALIASEOF'
! Micro Magic / Motif fallbacks (used only when name is not in fonts.dir)

-adobe-helvetica-medium-r-normal--8-80-75-75-p-46-iso8859-1     -misc-fixed-medium-r-normal--8-80-75-75-c-50-iso8859-1
-adobe-helvetica-medium-r-normal--10-100-75-75-p-56-iso8859-1   -misc-fixed-medium-r-normal--10-100-75-75-c-60-iso8859-1
-adobe-helvetica-medium-r-normal--12-120-75-75-p-67-iso8859-1   -misc-fixed-medium-r-normal--12-120-75-75-c-70-iso8859-1
-adobe-helvetica-medium-r-normal--14-140-75-75-p-78-iso8859-1   -misc-fixed-medium-r-normal--14-140-75-75-c-70-iso8859-1
-adobe-helvetica-bold-r-normal--12-120-75-75-p-69-iso8859-1     -misc-fixed-bold-r-normal--13-120-75-75-c-70-iso8859-1
-adobe-helvetica-bold-r-normal--14-140-75-75-p-78-iso8859-1     -misc-fixed-bold-r-normal--14-130-75-75-c-70-iso8859-1
-adobe-helvetica-medium-r-normal--18-180-75-75-p-98-iso8859-1   -misc-fixed-medium-r-normal--18-120-100-100-c-90-iso8859-1
-adobe-helvetica-bold-r-normal--18-180-75-75-p-103-iso8859-1    -misc-fixed-bold-r-normal--18-120-100-100-c-90-iso8859-1

-adobe-times-medium-r-normal--12-120-75-75-p-64-iso8859-1       -misc-fixed-medium-r-normal--12-120-75-75-c-70-iso8859-1
-adobe-times-medium-r-normal--14-140-75-75-p-74-iso8859-1       -misc-fixed-medium-r-normal--14-140-75-75-c-70-iso8859-1
-adobe-times-bold-r-normal--14-140-75-75-p-79-iso8859-1         -misc-fixed-bold-r-normal--14-130-75-75-c-70-iso8859-1

-adobe-courier-medium-r-normal--12-120-75-75-m-70-iso8859-1     -misc-fixed-medium-r-normal--12-120-75-75-c-70-iso8859-1
-adobe-courier-medium-r-normal--14-140-75-75-m-90-iso8859-1     -misc-fixed-medium-r-normal--14-140-75-75-c-70-iso8859-1

-fixed-medium-r-normal--8-*-*-*-c-*-*-*          -misc-fixed-medium-r-normal--8-80-75-75-c-50-iso8859-1
-fixed-medium-r-normal--10-*-*-*-c-*-*-*         -misc-fixed-medium-r-normal--10-100-75-75-c-60-iso8859-1
-fixed-medium-r-normal--12-*-*-*-c-*-*-*         -misc-fixed-medium-r-normal--12-120-75-75-c-70-iso8859-1
-fixed-medium-r-normal--13-*-*-*-c-*-*-*         -misc-fixed-medium-r-normal--13-120-75-75-c-70-iso8859-1
-fixed-medium-r-normal--14-*-*-*-c-*-*-*         -misc-fixed-medium-r-normal--14-140-75-75-c-70-iso8859-1
-fixed-bold-r-normal--12-*-*-*-c-*-*-*           -misc-fixed-bold-r-normal--13-120-75-75-c-70-iso8859-1
-fixed-bold-r-normal--14-*-*-*-c-*-*-*           -misc-fixed-bold-r-normal--14-130-75-75-c-70-iso8859-1
ALIASEOF

RUN cp /usr/share/fonts/X11/misc/fonts.alias /usr/share/fonts/X11/75dpi/fonts.alias 2>/dev/null || true \
    && cp /usr/share/fonts/X11/misc/fonts.alias /usr/share/fonts/X11/100dpi/fonts.alias 2>/dev/null || true

# ── Step 5: Rebuild font dirs ────────────────────────────────────────────────
RUN for dir in /usr/share/fonts/X11/misc /usr/share/fonts/X11/75dpi \
               /usr/share/fonts/X11/100dpi /usr/share/fonts/X11/Type1; do \
        if [ -d "$dir" ]; then \
            (cd "$dir" && mkfontdir . && mkfontscale . 2>/dev/null || true); \
        fi; \
    done \
    && fc-cache -f >/dev/null 2>&1 || true

# ── Step 6: Create user and setup CAD ────────────────────────────────────────
RUN useradd -m -s /bin/bash caduser \
    && usermod -aG sudo caduser \
    && echo "caduser ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/caduser \
    && chmod 0440 /etc/sudoers.d/caduser

RUN mkdir -p /home/caduser/cad \
    && cp ${MMI_TARBALL} /home/caduser/cad/ \
    && cd /home/caduser/cad \
    && gzip -dc ${MMI_TARBALL} | tar xvf - \
    && ln -s ${MMI_DIR} mmi_pd \
    && cd mmi_pd \
    && ln -s bin.i486-linux bin \
    && cp -r mmi_local.sample ../mmi_local \
    && chown -R caduser:caduser /home/caduser

# ── Step 6b: PDK importer + Magic→MAX importer (menus + sample) ──────────────
COPY max_pdk/pdk_import.tcl /opt/mmi-pdk/
COPY max_pdk/mag_import.tcl /opt/mmi-pdk/
COPY max_pdk/mag2gds.sh /opt/mmi-pdk/
COPY max_pdk/samples /opt/mmi-pdk/samples
COPY max_pdk/maxrc /tmp/mmi-pdk.maxrc
RUN mkdir -p /home/caduser/cad/mmi_local/max/pdk/samples /opt/pdks \
    && cp /opt/mmi-pdk/pdk_import.tcl /home/caduser/cad/mmi_local/max/pdk/ \
    && cp /opt/mmi-pdk/mag_import.tcl /home/caduser/cad/mmi_local/max/pdk/ \
    && cp /opt/mmi-pdk/mag2gds.sh /home/caduser/cad/mmi_local/max/pdk/ \
    && chmod 755 /opt/mmi-pdk/mag2gds.sh /home/caduser/cad/mmi_local/max/pdk/mag2gds.sh \
    && cp -a /opt/mmi-pdk/samples/. /home/caduser/cad/mmi_local/max/pdk/samples/ \
    && chmod 644 /opt/mmi-pdk/pdk_import.tcl /opt/mmi-pdk/mag_import.tcl \
    && (if [ -f /home/caduser/cad/mmi_local/max/.maxrc ]; then \
          cat /tmp/mmi-pdk.maxrc >> /home/caduser/cad/mmi_local/max/.maxrc; \
        else \
          cp /tmp/mmi-pdk.maxrc /home/caduser/cad/mmi_local/max/.maxrc; \
        fi) \
    && (if [ -f /home/caduser/.maxrc ]; then \
          cat /tmp/mmi-pdk.maxrc >> /home/caduser/.maxrc; \
        else \
          cp /tmp/mmi-pdk.maxrc /home/caduser/.maxrc; \
        fi) \
    && chown -R caduser:caduser /home/caduser/cad/mmi_local /home/caduser/.maxrc /opt/mmi-pdk /opt/pdks

# ── Step 7: Motif X resources (max / nst) ─────────────────────────────────────
# Separate RUN steps: Docker parse treats anything after a heredoc as a new
# instruction, so we cannot chain && after <<EOF in the same RUN.
RUN mkdir -p /home/caduser/cad/mmi_pd/app-defaults

RUN cat > /home/caduser/cad/mmi_pd/app-defaults/Mmi << 'XREOF'
! Micro Magic shared Motif resources
*Font: -misc-fixed-medium-r-normal--14-140-75-75-c-70-iso8859-1
*fontList: -misc-fixed-medium-r-normal--14-140-75-75-c-70-iso8859-1
*XmText.fontList: -misc-fixed-medium-r-normal--14-140-75-75-c-70-iso8859-1
*XmTextField.fontList: -misc-fixed-medium-r-normal--14-140-75-75-c-70-iso8859-1
*XmLabel.fontList: -misc-fixed-medium-r-normal--14-140-75-75-c-70-iso8859-1
*XmPushButton.fontList: -misc-fixed-medium-r-normal--14-140-75-75-c-70-iso8859-1
*XmCascadeButton.fontList: -misc-fixed-medium-r-normal--14-140-75-75-c-70-iso8859-1
*XmList.fontList: -misc-fixed-medium-r-normal--14-140-75-75-c-70-iso8859-1
*XmMenuBar.fontList: -misc-fixed-medium-r-normal--14-140-75-75-c-70-iso8859-1
*XmDrawingArea.fontList: -misc-fixed-medium-r-normal--14-140-75-75-c-70-iso8859-1
XREOF

RUN for app in Max max Nst nst; do \
        cp /home/caduser/cad/mmi_pd/app-defaults/Mmi \
           /home/caduser/cad/mmi_pd/app-defaults/$app; \
    done

RUN cat > /home/caduser/.Xresources << 'XREOF'
*Font: -misc-fixed-medium-r-normal--14-140-75-75-c-70-iso8859-1
*fontList: -misc-fixed-medium-r-normal--14-140-75-75-c-70-iso8859-1
*XmFontList: -misc-fixed-medium-r-normal--14-140-75-75-c-70-iso8859-1
*XmText*fontList: -misc-fixed-medium-r-normal--14-140-75-75-c-70-iso8859-1
*XmTextField*fontList: -misc-fixed-medium-r-normal--14-140-75-75-c-70-iso8859-1
*XmLabel*fontList: -misc-fixed-medium-r-normal--14-140-75-75-c-70-iso8859-1
*XmPushButton*fontList: -misc-fixed-medium-r-normal--14-140-75-75-c-70-iso8859-1
*XmCascadeButton*fontList: -misc-fixed-medium-r-normal--14-140-75-75-c-70-iso8859-1
*XmList*fontList: -misc-fixed-medium-r-normal--14-140-75-75-c-70-iso8859-1
*XmMenuBar*fontList: -misc-fixed-medium-r-normal--14-140-75-75-c-70-iso8859-1
Xft.dpi: 75
*dpi: 75
*Xft*Antialias: False
XREOF

RUN chown -R caduser:caduser /home/caduser

# ── Step 7b: Magic VLSI (tapeout mag2gds; not used by the Tcl paint dumper) ──
# Sky130 needs Magic ≥ 8.3; Ubuntu 20.04's apt package is too old.
RUN apt-get update && apt-get install -y --no-install-recommends \
        build-essential git m4 tcl-dev tk-dev \
        libx11-dev libcairo2-dev mesa-common-dev libglu1-mesa-dev zlib1g-dev \
    && git clone --depth 1 https://github.com/RTimothyEdwards/magic.git /tmp/magic \
    && cd /tmp/magic \
    && ./configure --prefix=/opt/magic \
    && make -j"$(nproc)" \
    && make install \
    && rm -rf /tmp/magic \
    && rm -rf /var/lib/apt/lists/*

# ── Step 8: Environment ──────────────────────────────────────────────────────
ENV MMI_TOOLS=/home/caduser/cad/mmi_pd \
    MMI_BROWSER=firefox \
    PDK_ROOT=/opt/pdks \
    PDK=sky130A \
    PATH="/opt/magic/bin:/home/caduser/cad/mmi_pd/bin:$PATH" \
    QT_X11_NO_MITSHM=1 \
    XKEYSYMDB=/usr/share/X11/XKeysymDB \
    LC_ALL=C \
    LANG=C \
    _XNO_XFT=1 \
    XAPPLRESDIR=/home/caduser/cad/mmi_pd/app-defaults

# ── Step 9: Entrypoint — point host X at Motif bitmap fonts ─────────────────
# MMI_XFONT_ROOT is a host path bind-mounted at the same absolute path.
# xset tells the X *server* (outside the container) to load that directory.
RUN cat > /entrypoint.sh << 'EOF'
#!/bin/bash
set -e

export MMI_TOOLS=/home/caduser/cad/mmi_pd
export PDK_ROOT="${PDK_ROOT:-/opt/pdks}"
export PDK="${PDK:-sky130A}"
export PATH="/opt/magic/bin:$MMI_TOOLS/bin:$PATH"
export _XNO_XFT=1
export XAPPLRESDIR=/home/caduser/cad/mmi_pd/app-defaults
export LC_ALL=C
export LANG=C

if [ -z "$DISPLAY" ]; then
    echo "ERROR: DISPLAY is not set. Run with -e DISPLAY=\$DISPLAY"
    exit 1
fi

# Wire up X11 authentication (cookie from run.sh, or host mount fallback)
if [ -n "${XAUTHORITY:-}" ] && [ -f "$XAUTHORITY" ]; then
    :
elif [ -f /home/caduser/.Xauthority-host ]; then
    cp -f /home/caduser/.Xauthority-host /home/caduser/.Xauthority
    chmod 600 /home/caduser/.Xauthority
    export XAUTHORITY=/home/caduser/.Xauthority
elif [ -f /tmp/.mmi-docker.xauth ]; then
    export XAUTHORITY=/tmp/.mmi-docker.xauth
fi

echo "=============================================="
echo "  Micro Magic CAD - Motif font setup"
echo "=============================================="
echo "  DISPLAY=${DISPLAY}"
echo "  XAUTHORITY=${XAUTHORITY:-<unset>}"
echo "  PDK_ROOT=${PDK_ROOT}"
echo "  Magic: $(command -v magic 2>/dev/null || echo missing)"

# Prefer host-visible font root from run.sh; fall back to image paths
FONT_ROOT="${MMI_XFONT_ROOT:-/usr/share/fonts/X11}"
echo "  Font root: $FONT_ROOT"

xrdb -merge /home/caduser/.Xresources 2>/dev/null || true
xrdb -merge /home/caduser/cad/mmi_pd/app-defaults/Mmi 2>/dev/null || true

# Build a comma-separated path: 75dpi first (correct Motif metrics)
FP_LIST=""
for sub in 75dpi misc 100dpi Type1 cyrillic; do
    d="$FONT_ROOT/$sub"
    if [ -d "$d" ] && [ -f "$d/fonts.dir" ]; then
        if [ -z "$FP_LIST" ]; then
            FP_LIST="$d"
        else
            FP_LIST="$FP_LIST,$d"
        fi
        echo "  + $d"
    fi
done

if [ -n "$FP_LIST" ]; then
    # Replace font path entirely — host fontconfig "core" fonts make Motif huge
    if xset fp= "$FP_LIST" 2>/tmp/xset-fp.err; then
        echo "  Font path replaced with Motif bitmap dirs"
    else
        echo "  WARN: xset fp= failed:"
        cat /tmp/xset-fp.err 2>/dev/null || true
        for d in $(echo "$FP_LIST" | tr ',' ' '); do
            xset +fp "$d" 2>/dev/null || true
        done
    fi
    xset fp rehash 2>/dev/null || true
else
    echo "  WARN: No bitmap font dirs found under $FONT_ROOT"
fi

echo ""
echo "--- Font Path ---"
xset q 2>/dev/null | grep -A 20 "Font Path" | head -25 || true

echo ""
echo "--- Motif-critical fonts ---"
MISSING=0
for font in \
    "-adobe-helvetica-medium-r-normal--12-120-75-75-p-67-iso8859-1" \
    "-adobe-helvetica-medium-r-normal--14-140-75-75-p-78-iso8859-1" \
    "-misc-fixed-medium-r-normal--14-140-75-75-c-70-iso8859-1" \
    "fixed" "9x15"; do
    if xlsfonts 2>/dev/null | grep -qF "$font"; then
        echo "  [OK] $font"
    else
        echo "  [MISSING] $font"
        MISSING=1
    fi
done
if [ "$MISSING" -eq 1 ]; then
    echo ""
    echo "  WARN: Some XLFD fonts missing. max/nst may still look wrong."
    echo "  On native Linux, re-run via ./run.sh so fonts are bind-mounted"
    echo "  at a path the host X server can read (MMI_XFONT_ROOT)."
fi

echo ""
echo "=============================================="
echo "  Starting: $*"
echo "=============================================="
echo ""

exec "$@"
EOF

RUN chmod +x /entrypoint.sh

USER caduser
WORKDIR /home/caduser
ENTRYPOINT ["/entrypoint.sh"]
CMD ["/bin/bash"]
