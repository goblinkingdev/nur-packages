{
  lib,
  stdenv,
  fetchFromGitHub,
  fetchPnpmDeps,
  buildNpmPackage,
  nodejs_24,
  pnpm,
  pnpmConfigHook,
  makeWrapper,
  electron,
  makeDesktopItem,
  glib,
  nss,
  nspr,
  atk,
  at-spi2-atk,
  at-spi2-core,
  cups,
  dbus,
  expat,
  libdrm,
  pango,
  cairo,
  gtk3,
  gdk-pixbuf,
  mesa,
  libgbm,
  vulkan-loader,
  libGL,
  wayland,
  libxkbcommon,
  alsa-lib,
  libsecret,
  udev,
  libx11,
  libxcomposite,
  libxdamage,
  libxext,
  libxfixes,
  libxrandr,
  libxcb,
  libxshmfence,
  libxscrnsaver,
}:

let
  electronLibs = [
    glib
    nss
    nspr
    atk
    at-spi2-atk
    at-spi2-core
    cups
    dbus
    expat
    libdrm
    pango
    cairo
    gtk3
    gdk-pixbuf
    mesa
    libgbm
    vulkan-loader
    libGL
    wayland
    libxkbcommon
    alsa-lib
    libsecret
    udev
    libx11
    libxcomposite
    libxdamage
    libxext
    libxfixes
    libxrandr
    libxcb
    libxshmfence
    libxscrnsaver
  ];

  sableSrc = fetchFromGitHub {
    owner = "SableClient";
    repo = "Sable";
    rev = "v1.15.3";
    hash = "sha256-KxTpV1XKjeEhTJEWKdcOkEwATs1RzfoGP1vro6xHP5U=";
  };

  sableWebApp = stdenv.mkDerivation {
    pname = "sable-webapp";
    version = "dev";
    src = sableSrc;

    nativeBuildInputs = [
      nodejs_24
      pnpm
      pnpmConfigHook
    ];

    pnpmDeps = fetchPnpmDeps {
      pname = "sable-webapp";
      version = "dev";
      src = sableSrc;
      fetcherVersion = 2;
      hash = "sha256-F3GT19uu98h5HbwNLKDTbMk7WkwTuLRCmQECs29i5pk=";
    };

    buildPhase = ''
      runHook preBuild
      pnpm build
      runHook postBuild
    '';

    installPhase = ''
      runHook preInstall
      cp -r dist $out
      runHook postInstall
    '';
  };

  desktopItem = makeDesktopItem {
    name = "sable-desktop";
    exec = "sable-desktop %U";
    icon = "sable-desktop";
    desktopName = "Sable";
    comment = "Unofficial Electron desktop wrapper for Sable Matrix client";
    categories = [
      "Network"
      "InstantMessaging"
    ];
    mimeTypes = [ "x-scheme-handler/element" ];
  };

in
buildNpmPackage {
  pname = "sable-desktop";
  version = "1.0.3";

  src = fetchFromGitHub {
    owner = "goblinkingdev";
    repo = "sable-electron";
    rev = "v1.0.3";
    hash = "sha256-sdXVc5V+cDTN9qEyR2ygQE+t8lc5BPAadWSibRCd14c=";
  };

  npmDepsHash = "sha256-wV1D9t14DpKvIdyvk9Ka4yLQCC4YlRaQY8I3FUYz8+Q=";

  nativeBuildInputs = [
    nodejs_24
    makeWrapper
    electron
  ];

  buildInputs = electronLibs;

  env = {
    ELECTRON_SKIP_BINARY_DOWNLOAD = "1";
    ELECTRON_OVERRIDE_DIST_PATH = "${electron}/libexec/electron";
  };

  buildPhase = ''
    runHook preBuild
    mkdir -p sable
    cp -r ${sableWebApp} sable/dist
    npm run build:electron
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    mkdir -p $out/lib/sable-desktop $out/bin $out/share/applications

    cp -r dist-electron package.json $out/lib/sable-desktop/
    cp -r ${sableWebApp} $out/lib/sable-desktop/dist

    makeWrapper ${electron}/bin/electron $out/bin/sable-desktop \
      --add-flags "$out/lib/sable-desktop" \
      --set LD_LIBRARY_PATH "${lib.makeLibraryPath electronLibs}:/run/opengl-driver/lib"

    cp ${desktopItem}/share/applications/sable-desktop.desktop $out/share/applications/

    runHook postInstall
  '';

  passthru = {
    desktopItem = desktopItem;
  };

  meta = with lib; {
    description = "Unofficial Electron desktop wrapper for Sable Matrix client";
    homepage = "https://github.com/goblinkingdev/sable-electron";
    changelog = "https://github.com/goblinkingdev/commits/master";
    license = licenses.agpl3Only;
    maintainers = with maintainers; [ "goblinkingdev" ];
    mainProgram = "sable-desktop";
    platforms = platforms.linux ++ platforms.darwin;
  };
}
