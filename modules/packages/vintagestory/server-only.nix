{
  systems = [ "x86_64-linux" ];
  perSystem = { pkgs, ... }: {
    packages.vintagestory-server = pkgs.callPackage (
      {
        versionCheckHook,
        stdenv,
        makeWrapper,
        lib,
        fetchurl,
        dotnet-runtime_10,
        ...
      }:
      let
        pname = "vintagestory";
        version = "1.22.7";

        src = fetchurl {
          url = "https://cdn.vintagestory.at/gamefiles/stable/vs_server_linux-x64_${version}.tar.gz";
          hash = "sha256-p9SlIGBFkKlt6BLubGuvRATUPYbPHsT7rBs6WAtSyEc=";
        };

      in
      stdenv.mkDerivation {
        inherit pname version src;
        __structuredAttrs = true;
        sourceRoot = ".";

        nativeBuildInputs = [
          makeWrapper
        ];

        installPhase = ''
          runHook preInstall

          mkdir -p $out/share/vintagestory $out/bin
          cp -r * $out/share/vintagestory

          runHook postInstall
        '';

        preFixup = ''
          makeWrapper ${lib.getExe dotnet-runtime_10} $out/bin/vintagestory-server \
            "''${makeWrapperArgs[@]}" \
            --add-flags $out/share/vintagestory/VintagestoryServer.dll
        '';

        doInstallCheck = true;
        installCheckInputs = [ versionCheckHook ];

        meta = {
          description = "In-development indie sandbox game about innovation and exploration";
          homepage = "https://www.vintagestory.at/";
          license = lib.licenses.unfree;
          sourceProvenance = [ lib.sourceTypes.binaryBytecode ];
          platforms = [ "x86_64-linux" ];
          mainProgram = "vintagestory-server";
        };
      }
    ) { };
  };
}
