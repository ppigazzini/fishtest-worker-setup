@echo off
::install fishtest worker
C:\tools\msys64\msys2_shell.cmd -defterm -mingw64 -here -c "bash 02_install_worker.sh 2>&1 | tee 02_install_worker.sh.log"
