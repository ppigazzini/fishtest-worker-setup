@echo off
::upgrade chocolatey and msys2 and trigger the update of the msys2 packages
choco upgrade chocolatey -y
choco upgrade msys2 -f -y
