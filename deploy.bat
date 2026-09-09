@echo off
chcp 65001 >nul
title Deploy KONGFANG UNITED site
set "ND=C:\Users\User\node\node-v22.13.1-win-x64"
set "PATH=%ND%;%PATH%"
pushd "%~dp0"

if exist "%~dp0netlify-token.txt" (
  set /p NETLIFY_AUTH_TOKEN=<"%~dp0netlify-token.txt"
) else (
  echo [ERROR] netlify-token.txt not found in this folder.
  echo Create it and paste your Netlify token ^(nfp_...^) inside, then run again.
  goto end
)

echo(
echo ==== KONGFANG UNITED - Deploy to Netlify ====
echo Folder: %CD%
"%ND%\node.exe" --version
echo(
echo Deploying "_deploy" to Netlify (production) ...
echo(
call "%ND%\npx.cmd" -y netlify-cli deploy --dir "%CD%\_deploy" --prod --site a97649ab-73e5-4c1e-9267-50e1c6859582

echo(
echo ==== FINISHED - scroll up for the Website URL ====

:end
echo(
echo Press any key to close...
pause >nul
popd
