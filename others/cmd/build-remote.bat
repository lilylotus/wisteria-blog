@echo off

for /f "tokens=2 delims==" %%a in ('wmic os get localdatetime /value') do set "dt=%%a"
set "YYYY=%dt:~0,4%"
set "MM=%dt:~4,2%"
set "DD=%dt:~6,2%"
set "HH=%dt:~8,2%"
set "Min=%dt:~10,2%"
set "Sec=%dt:~12,2%"
rem echo %YYYY%-%MM%-%DD%_%HH%:%Min%:%Sec%
set DATE_TIMER=%YYYY%%MM%%DD%%HH%%Min%%Sec%
set TIMER=%HH%%Min%%Sec%

set build_dir=%~dp0
echo build_dir=%build_dir%

rmdir /s /q build

set SERVER_USER=koalops
set SERVER_HOST=10.0.249.23
set SERVER_PORT=60022
set EXTEND_DIR=/data/koal/idaas/idaas-sso/extend
set JAR_PREFIX=sso_feature_for_yj
set JAR_NAME=%JAR_PREFIX%-%DATE_TIMER%.jar
set DOCKER_CONTAINER=idaas-sso

call gradlew clean jar -x test
cd %build_dir%build\libs
@REM xcopy /y authn-api*.jar %build_dir%build\libs\authn-api.jar
ren %JAR_PREFIX%*.jar %JAR_NAME%

scp -P %SERVER_PORT% -i C:\Users\Administrator\Desktop\temporary\keys\id_rsa %JAR_NAME% %SERVER_USER%@%SERVER_HOST%:/home/%SERVER_USER%/idaas-id/
ssh -p %SERVER_PORT% -i C:\Users\Administrator\Desktop\temporary\keys\id_rsa %SERVER_USER%@%SERVER_HOST% "cd /home/%SERVER_USER%/idaas-id/ ; sudo rm -f %EXTEND_DIR%/%JAR_PREFIX%*.jar ; sudo cp %JAR_NAME% %EXTEND_DIR%/ ; docker restart %DOCKER_CONTAINER%"

cd %build_dir%