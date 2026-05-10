{ lib
, stdenv
, fetchFromGitHub
, fetchPnpmDeps
, buildNpmPackage
, nodejs_24
, pnpm
, pnpmConfigHook
, makeWrapper
, electron
, glib
, nss
, nspr
, atk
, at-spi2-atk
, at-spi2-core
, cups
, dbus
, expat
, libdrm
, pango
, cairo
, gtk3
, gdk-pixbuf
, mesa
, libgbm
, vulkan-loader
, libGL
, wayland
, libxkbcommon
, alsa-lib
, libsecret
, udev
, xorg
}:

let
  electronLibs = [
    glib nss nspr atk at-spi2-atk at-spi2-core cups dbus expat libdrm
    pango cairo gtk3 gdk-pixbuf mesa libgbm vulkan-loader libGL
    wayland libxkbcommon alsa-lib libsecret udev
    xorg.libX11 xorg.libXcomposite xorg.libXdamage xorg.libXext
    xorg.libXfixes xorg.libXrandr xorg.libxcb xorg.libxshmfence xorg.libXScrnSaver
  ];

  sableSrc = fetchFromGitHub {
    owner = "SableClient";
    repo = "Sable";
    rev = "v1.0.1b";
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

in
buildNpmPackage {
  pname = "sable-desktop";
  version = "1.0.0";

  src = fetchFromGitHub {
    owner = "GoblinKingDev";
    repo = "sable-electron";
    rev = "v1.0.1b"; 
    hash = lib.fakeHash;  };

  npmDepsHash = "sha256-5LgXHJez18yo9Z8MtBMie1P6U2PLLlO4m0q5cxK3NlM=";

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
    mkdir -p $out/lib/sable-desktop $out/bin
    
    cp -r dist-electron package.json $out/lib/sable-desktop/
    cp -r ${sableWebApp} $out/lib/sable-desktop/dist
    
    makeWrapper ${electron}/bin/electron $out/bin/sable-desktop \
      --add-flags "$out/lib/sable-desktop" \
      --set LD_LIBRARY_PATH "${lib.makeLibraryPath electronLibs}:/run/opengl-driver/lib"
      
    runHook postInstall
  '';

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
