@echo off
if exist {%TEMP%\balabit.out} ( del %TEMP%\balabit.out)


wmic /output:%TEMP%\wmic.out qfe list full /format:csv

dxdiag /whql:off /x %TEMP%\dxdiag.out
:LOOP
find /i "xml" %TEMP%\dxdiag.out >nul
if %errorlevel% neq 0 ( echo "Waiting for dxdiag to be generated" & timeout 5 & goto LOOP )
echo "==================================DXDIAG BEGIN===================================" >%TEMP%\balabit.out
copy %TEMP%\balabit.out+%TEMP%\dxdiag.out %TEMP%\balabit.out
del %TEMP%\dxdiag.out

systeminfo /nh /fo csv >%TEMP%\systeminfo.out
echo "==================================SYSTEMINFO BEGIN===================================" >>%TEMP%\balabit.out
copy %TEMP%\balabit.out+%TEMP%\systeminfo.out %TEMP%\balabit.out
del %TEMP%\systeminfo.out

ipconfig /all >%TEMP%/ipconfig.out
echo "==================================IPCONFIG BEGIN===================================" >>%TEMP%\balabit.out
copy %TEMP%\balabit.out+%TEMP%\ipconfig.out %TEMP%\balabit.out
del %TEMP%\ipconfig.out

netstat -e >%TEMP%/netstat.out
echo "==================================NETSTAT BEGIN===================================" >>%TEMP%\balabit.out
copy %TEMP%\balabit.out+%TEMP%\netstat.out %TEMP%\balabit.out
del %TEMP%\netstat.out

echo "==================================WMIC BEGIN===================================" >>%TEMP%\balabit.out
copy %TEMP%\balabit.out+%TEMP%\wmic.out %TEMP%\balabit.out
del %TEMP%\wmic.out

echo "Files are in %TEMP%"
