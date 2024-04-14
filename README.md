### Overview
Fishtest worker setup scripts for Windows 10 and Windows 11, that installs [msys2](https://www.msys2.org) using [winget](https://learn.microsoft.com/en-us/windows/package-manager/winget/), the Microsoft Windows package manager.

### Instructions
- run `00_install_winget_msys2_admin.cmd` with administrator privileges to install the required `winget` and `msys2`. Note that `winget` should be already installed on up-to-date versions of Windows 10 and Windows 11
- run `02_install_worker.cmd`to setup the fishtest worker along with the required `msys2` applications
- periodically, run `02_install_worker.cmd` twice to update `msys2`: the first execution updates the core packages, the second one the application packages
