{ lib
, buildDotnetModule
, fetchFromGitHub
, dotnet-sdk_8
, dotnet-runtime_8
, openssl
}:

buildDotnetModule rec {
  pname = "mawtrix";
  version = "0.6";

  src = fetchFromGitHub {
    owner = "Entarno54";
    repo = "Mawtrix";
    rev = "8353ceb20168405259eb56402c2978290af07857";
    hash = "sha256-mMeWXojnCzCM9iM4Zfi1TR3KheTHpB7VX64McRNqgmU=";
  };

  nugetDeps = "/deps.json";

  projectFile = "Mawtrix/Mawtrix.csproj";
  executables = [ "Mawtrix" ];

  dotnet-sdk = dotnet-sdk_8;
  dotnet-runtime = dotnet-runtime_8;

  buildInputs = [ openssl ];

  meta = with lib; {
    description = "A simple Matrix TUI client written in C#";
    homepage = "https://github.com/Entarno54/Mawtrix";
    changelog = "https://github.com/Entarno54/Mawtrix/commits/main";
    license = licenses.mit;
    maintainers = with maintainers; [ goblinkingdev ];
    mainProgram = "Mawtrix";
    platforms = platforms.linux ++ platforms.darwin;
  };
}