@echo off
REM Project: A script for starting all ecb-api services and MetraOffer on a single host.
REM 	     Intended for ECB 7.1.0 deployment use, use the default profile from branch ECB-API-CONFIG-CD 
REM NOTE:  By default, script will terminate all ecb-api process before restart. 
REM README: 
REM CHECKLIST:
REM	    1. Verify server ports are not already taken by other applicatiions on your system. 
REM 	    2. Access to the ECB database
REM 	    3. Replace the values for CONFIG_LOCAL_REPO(local repo path to ECB-API-CONFIG) ,JARS_LOCATION,UI_JARS_LOCATION,LOGS_LOCATION(gerenated logs) 
REM         4. Replace the values for CONFIG_LABEL( branch name ECB-API-CONFIG-CD as default)
REM         5. Replace the values for ECB_CONFIG_REG_JAR,ECB_SECURITY_JAR,jars_list[] with a list of jars you have
REM         6. Replace the values for URL, same as the ecb-eureka-host in application.yml 
REM 	    7. Replace the values for ecb-keystore, ecb-keystore
REM         8. git clone ECB-API-CONFIG to a local repo, backup the original files if needed 
REM         9. Set JAVA_HOME using the java path on your system
REM STEPS : example 
REM         1. create C:\ecb-api-solo\ and C:\ecb-api-solo\logs and copy ecb-startup-solo.bat to C:\ecb-api-solo\
REM         2. git clone ECB-API-CONFIG to local path C:\ecb-api-solo\ECB-API-CONFIG
REM         3. copy ecb-api, metraoffer jars to C:\ecb-api-solo\packages\ecb-api\17.1.0\12 and C:\ecb-api-solo\packages\ecb-ui-metraoffer\2.0.0\6
REM         4. copy your key to C:\ecb-api-solo\keys
REM         5. open CMD - run ecb-startup-solo.bat from c:\ecb-api-solo
REM OUTPUT: startup.log and services logs are in C:\ecb-api-solo\logs
REM         Generate ecb-startup-solo.failed or ecb-startup-solo.passed when it's done.
REM 
REM Additional overrides in application.yml 
REM 	ecb-keystore-alias: 
REM 	ecb-dbms: 
REM 	ecb-datasource-classname: 
REM 	ecb-datasource-username: 
REM 	ecb-datasource-password: 
REM 	ecb-db-servername: 
REM 	ecb-db-name: 
REM 	ecb-hash-key: 
REM 	config-registry-port: 8888
REM 	security-port: 8443
REM 	billing-port: 8091
REM 	customer-port: 8095
REM 	foundation-port: 8097
REM 	metraoffer-ui-port: 8074
REM 	pricing-port: 8099
REM 	catalog-port: 8093
REM ********************************************
SET workspace=C:\ecb-api-solo
SET ecb-keystore=%workspace%\keys\ecbkeystore.jks
SET ecb-keystore-password=ecbapipwd
SET CONFIG_LOCAL_REPO=%workspace%\ECB-API-CONFIG
SET JARS_LOCATION=%workspace%\packages\ecb-api\17.1.0\12
SET UI_JARS_LOCATION=%workspace%\packages\ecb-ui-metraoffer\2.0.0\6
SET LOGS_LOCATION=%workspace%\logs
SET CONFIG_LABEL=ECB-API-CONFIG-CD
SET URL=https://localhost:8888
SET ECB_CONFIG_REG_JAR=ecb-config-registry-17.1.169.jar
SET ECB_SECURITY_JAR=ecb-security-17.1.0.371.jar
SET UI_JAR=ecb-metraoffer-ui-17.1.191.jar
SET jars_list[0]=ecb-catalog-service-17.1.0.522.jar
SET jars_list[1]=ecb-customer-service-17.1.0.397.jar
SET jars_list[2]=ecb-foundation-service-17.1.0.432.jar 
SET jars_list[3]=ecb-pricing-service-17.1.0.376.jar
SET jars_list[4]=ecb-billing-service-17.1.0.393.jar
REM ********************************************
SET svc_list[0]=ecb-catalog-service
SET svc_list[1]=ecb-customer-service
SET svc_list[2]=ecb-foundation-service
SET svc_list[3]=ecb-pricing-service
SET svc_list[4]=ecb-billing-service
set all_list=ecb-config-registry ecb-security ecb-catalog-service ecb-customer-service ecb-foundation-service ecb-pricing-service ecb-billing-service ecb-metraoffer

SET CONFIG_REG_URL=%URL%/eureka/apps
SET SECURITY_REG_URL=%CONFIG_REG_URL%/ecb-security
SET CATALOG_URL=%CONFIG_REG_URL%/ecb-product-catalog
SET CUSTOMER_URL=%CONFIG_REG_URL%/ecb-customer
SET FOUNDATION_URL=%CONFIG_REG_URL%/ecb-foundation
SET PRICING_URL=%CONFIG_REG_URL%/ecb-pricing
SET BILLING_URL=%CONFIG_REG_URL%/ecb-billing
SET UI_URL=%CONFIG_REG_URL%/ecb-metraoffer

SET VM_HEAP=-Xmx128m
SET ECB_JAVA_OPTIONS=%VM_HEAP% -Djavax.net.ssl.trustStore=%ecb-keystore%  -Djavax.net.ssl.trustStorePassword=%ecb-keystore-password%


SET JAVA-PROCESS=%LOGS_LOCATION%\java_process
SET ECB-PROCESS=%LOGS_LOCATION%\ecb_process
SET ECB_API_START_LOG=%LOGS_LOCATION%\startup.log
If exist %LOGS_LOCATION%\ecb-startup-solo.failed (del %LOGS_LOCATION%\ecb-startup-solo.failed )
If exist %LOGS_LOCATION%\ecb-startup-solo.passed (del %LOGS_LOCATION%\ecb-startup-solo.passed )

IF NOT DEFINED JAVA_HOME GOTO MISSING
IF NOT EXIST %CONFIG_LOCAL_REPO% GOTO MISSING
IF NOT EXIST %JARS_LOCATION% GOTO MISSING
IF NOT EXIST %UI_JARS_LOCATION% GOTO MISSING


set StartTime=%time%
echo ECB-API servicces restart at %date% %time% > %ECB_API_START_LOG%
If exist %JAVA-PROCESS% (del %JAVA-PROCESS% )
If exist %ECB-PROCESS% (del %ECB-PROCESS%)

REM :CHECK_ECB_API_PROCESS, terminate all ecb-api process before restart
SETLOCAL EnableDelayedExpansion
wmic  process where caption="java.exe" get commandline,processid > %JAVA-PROCESS%
for %%s in (%all_list%) do (

  type %JAVA-PROCESS% 2>&1 |findstr /n %%s >> %ECB-PROCESS%
)
REM If not exist (%ECB-PROCESS%) ( GOTO START_ECB_SERVICES)
for %%A in (%ECB-PROCESS%) do if %%~zA==0 GOTO START_ECB_SERVICES

for /f "tokens=*" %%a in (%ECB-PROCESS%) do (
  echo line %%a >> %ECB_API_START_LOG%
  
  for %%A in (%%a ) do  set last=%%A
  
  echo ecb process id !last!
  echo kill process ID !last! >> %ECB_API_START_LOG%
  Taskkill /PID !last! /F 
  timeout /t 1 /nobreak
  
)
timeout /t 2 /nobreak
:START_ECB_SERVICES
echo cleanup logs >> %ECB_API_START_LOG%
for %%b in (ecb-config-registry ecb-security ecb-catalog-service ecb-customer-service ecb-foundation-service ecb-pricing-service ecb-billing-service MetraOfferUI ) do ( 
If exist %LOGS_LOCATION%\%%b.log (
echo Removing %LOGS_LOCATION%\%%b.log >> %ECB_API_START_LOG%
del %LOGS_LOCATION%\%%b.log )
)
echo Starting all ECB services >> %ECB_API_START_LOG%
time /t >> %ECB_API_START_LOG%

REM :START_CONFIG_REG
echo Starting ecb-config-registry, log is in ecb-config-registry.log
SET CMD_LINE=start /B "ECB Config Registry Server" "%JAVA_HOME%\bin\java" %VM_HEAP% -Djavax.net.ssl.trustStore=%ecb-keystore% -Djavax.net.ssl.trustStorePassword=%ecb-keystore-password% -jar %JARS_LOCATION%\%ECB_CONFIG_REG_JAR% --spring.cloud.config.server.git.uri=file://%CONFIG_LOCAL_REPO% --spring.cloud.config.label=%CONFIG_LABEL%
echo %CMD_LINE% >> %ECB_API_START_LOG%
(%CMD_LINE%) > %LOGS_LOCATION%\ecb-config-registry.log <nul
timeout /t 15 /nobreak
if not exist %LOGS_LOCATION%\ecb-config-registry.log goto MISSING
call :_CHECK_RUN %LOGS_LOCATION%\ecb-config-registry.log
if %errorlevel% neq 0 (GOTO FAILTOSTART & exit /b 1) 
echo ecb-config-registry process is running  


REM :CHECK_CONFIG_REG_URL
echo VERIFYING %CONFIG_REG_URL% status >> %ECB_API_START_LOG%
curl --insecure -I %CONFIG_REG_URL% 2>&1 | findstr "200 OK" > nul
if %errorlevel% neq 0 (GOTO FAILTOSTART & exit /b 1) 
echo %CONFIG_REG_URL% is up  >> %ECB_API_START_LOG%
echo %CONFIG_REG_URL% is up 


REM :START_SECURITY
echo Starting ECB Security Service, log is in ecb-security.log >> %ECB_API_START_LOG%
echo Starting ecb-security, please wait...
set CMD_LINE=start /B "ECB Security"  "%JAVA_HOME%\bin\java" %ECB_JAVA_OPTIONS%  -jar %JARS_LOCATION%\%ECB_SECURITY_JAR% --spring.cloud.config.uri=%URL%/config  --spring.cloud.config.label=%CONFIG_LABEL% 
echo %CMD_LINE% >> %ECB_API_START_LOG% 
(%CMD_LINE%) > %LOGS_LOCATION%\ecb-security.log <nul
timeout /t 15 /nobreak

if not exist  %LOGS_LOCATION%\ecb-security.log goto MISSING
call :_CHECK_RUN %LOGS_LOCATION%\ecb-security.log
if %errorlevel% neq 0 (GOTO FAILTOSTART & exit /b 1) 
echo ecb-security process is running  

REM :CHECK_SECURITY_URL
echo  VERIFYING %SECURITY_REG_URL% status >> %ECB_API_START_LOG%
curl --insecure -I %SECURITY_REG_URL%  2>&1 | findstr "200 OK" > nul 
REM if %errorlevel% neq 0 (CALL :_FAILTOSTART & exit /b 1) 
if %errorlevel% neq 0 (GOTO FAILTOSTART & exit /b 1) 
echo %SECURITY_REG_URL% is up  >> %ECB_API_START_LOG%
echo %SECURITY_REG_URL% is up  

REM start the rest of ecb-api services
REM :START_SVC
for %%s in (0 1 2 3 4) do (
echo Starting !svc_list[%%s]!  Service using !jars_list[%%s]! ... >> %ECB_API_START_LOG%
start /B " !svc_list[%%s]! "  "%JAVA_HOME%\bin\java" %ECB_JAVA_OPTIONS%  -jar %JARS_LOCATION%\!jars_list[%%s]! --spring.cloud.config.uri=%URL%/config  --spring.cloud.config.label=%CONFIG_LABEL% > %LOGS_LOCATION%\!svc_list[%%s]!.log <nul 
 )
timeout /t 50  /nobreak

for %%a in (ecb-catalog-service ecb-customer-service ecb-foundation-service ecb-pricing-service ecb-billing-service) do (
call :_CHECK_RUN %LOGS_LOCATION%\%%a.log
if %errorlevel% neq 0 (GOTO FAILTOSTART & exit /b 1) 
echo %%a process is running  
)

:CHECK_SERVICES_URL
echo VERIFYING %CATALOG_URL% status >> %ECB_API_START_LOG%
curl --insecure -I %CATALOG_URL% 2>&1 | findstr "200 OK" > nul
if %errorlevel% neq 0 (GOTO FAILTOSTART & exit /b 1) 
echo %CATALOG_URL% is up >> %ECB_API_START_LOG%

echo VERIFYING %CUSTOMER_URL% status >> %ECB_API_START_LOG%
curl --insecure -I %CUSTOMER_URL% 2>&1 | findstr "200 OK" > nul
if %errorlevel% neq 0 (GOTO FAILTOSTART & exit /b 1) 
echo %CUSTOMER_URL% is up >> %ECB_API_START_LOG%

echo VERIFYING %FOUNDATION_URL% status >> %ECB_API_START_LOG%
curl --insecure -I %FOUNDATION_URL% 2>&1 | findstr "200 OK" > nul
if %errorlevel% neq 0 (GOTO FAILTOSTART & exit /b 1) 
echo %FOUNDATION_URL% is up >> %ECB_API_START_LOG%

echo VERIFYING %PRICING_URL%  status >> %ECB_API_START_LOG%
curl --insecure -I %PRICING_URL% 2>&1 | findstr "200 OK" > nul
if %errorlevel% neq 0 (GOTO FAILTOSTART & exit /b 1) 
echo %PRICING_URL% is up >> %ECB_API_START_LOG%

echo VERIFYING %BILLING_URL%  status >> %ECB_API_START_LOG%
curl --insecure -I %BILLING_URL% 2>&1 | findstr "200 OK" > nul
if %errorlevel% neq 0 (GOTO FAILTOSTART & exit /b 1) 
echo %BILLING_URL% is up >> %ECB_API_START_LOG%

:START_UI
echo Starting ECB METRAOFFER UI ... >> %ECB_API_START_LOG%
start /B "ECB METRAOFFER UI "  "%JAVA_HOME%\bin\java" %ECB_JAVA_OPTIONS%  -jar %UI_JARS_LOCATION%\%UI_JAR% --spring.cloud.config.uri=%URL%/config  --spring.cloud.config.label=%CONFIG_LABEL% > %LOGS_LOCATION%\MetraOfferUI.log <nul
echo Starting ECB METRAOFFER UI...,please wait
timeout /t 40 /nobreak
if not exist %LOGS_LOCATION%\MetraOfferUI.log goto MISSING
call :_CHECK_RUN %LOGS_LOCATION%\MetraOfferUI.log
if %errorlevel% neq 0 (GOTO FAILTOSTART & exit /b 1) 
echo ecb-metraoffer process is running  


:CHECK_UI_URL
echo VERIFYING METRAOFFER UI  status >> %ECB_API_START_LOG%
curl --insecure -I %UI_URL% 2>&1 | findstr "200 OK" > nul
if %errorlevel% neq 0 (GOTO FAILTOSTART & exit /b 1) 
echo %UI_URL% is running >> %ECB_API_START_LOG%
echo METRAOFFER UI is up  
echo 0 > %LOGS_LOCATION%\ecb-startup-solo.passed
GOTO END

:FAILTOSTART
echo Failed to start services, please check service log for errors >> %ECB_API_START_LOG%
echo Failed to start services, please check service log  for more information 
echo 1 > %LOGS_LOCATION%\ecb-startup-solo.failed
GOTO END

:MISSING
echo Missing PATH or FILE or JAVA_HOME ... 
echo Missing PATH or FILE or JAVA_HOME ... >> %ECB_API_START_LOG%
echo 1 > %LOGS_LOCATION%\ecb-startup-solo.failed
GOTO END

:_CHECK_RUN  
 SET max_time=150
 SET total_time=0
 SET wait_time=30
 SET file_name=%~1 
 echo %file_name%
 :loop
 
 findstr /C:"is running" %file_name% > nul
 if %errorlevel% equ 0 EXIT /B 0
 if %total_time% gtr %max_time% EXIT /B 1
 Echo Waiting for services to come up ... %total_time%
 timeout %wait_time% /nobreak
 SET /A total_time=total_time+wait_time
 GOTO loop
 goto :EOF
:END
echo ****END**** 

                    

