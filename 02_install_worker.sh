#!/bin/bash
# install and configure fishtest worker

# print CPU information
cpu_model=$(grep "^model name" /proc/cpuinfo | uniq | cut -d ':' -f 2)
n_cpus=$(grep "^physical id" /proc/cpuinfo | uniq | wc -l)
online_cores=$(grep "^processor" /proc/cpuinfo | wc -l)
n_siblings=$(grep "^siblings" /proc/cpuinfo | uniq | cut -d ':' -f 2)
n_cpu_cores=$(grep "^core id" /proc/cpuinfo | uniq | wc -l)
total_siblings=$(($n_cpus * $n_siblings))
total_cpu_cores=$(($n_cpus * $n_cpu_cores))
printf "CPU model : $cpu_model\n"
printf "CPU       : %3d  -  Online cores    : %3d\n" $n_cpus $online_cores
printf "Siblings  : %3d  -  Total siblings  : %3d\n" $n_siblings $total_siblings
printf "CPU cores : %3d  -  Total CPU cores : %3d\n" $n_cpu_cores $total_cpu_cores

# read fishtest credentials and number of cores to be contributed
echo
read -p "Write your fishtest username: " usr_name
read -p "Write your fishtest password: " usr_pwd
read -p "Write the number of cores to be contributed to fishtest (max suggested 'Total CPU cores - 1'): " n_cores

# install packages if not already installed
pacman -Syuu --noconfirm
pacman -S --noconfirm --needed git make mingw-w64-ucrt-x86_64-gcc mingw-w64-ucrt-x86_64-python3 mingw-w64-ucrt-x86_64-uv

# delete old worker
rm -rf worker
# clone worker from fishtest
git init fishtest
pushd fishtest
git remote add origin https://github.com/official-stockfish/fishtest.git
git config core.sparseCheckout true
echo "worker/" >> .git/info/sparse-checkout
git pull --depth=1 origin master
popd
mv fishtest/worker .
rm -rf fishtest

# write fishtest.cfg and a runner script
cd worker
uv run worker.py "$usr_name" "$usr_pwd" --concurrency "$n_cores" --only_config --no_validation && echo "Successfully set the concurrency value" || echo "Error: restart the script setting a proper concurrency value"

cat << EOF >> fishtest.cmd
@echo off
set PATH=C:\msys64\ucrt64\bin;C:\msys64\usr\bin;%PATH%
uv run worker.py
EOF
