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
pacman -S --noconfirm --needed curl unzip make mingw-w64-x86_64-gcc mingw-w64-x86_64-python3

# delete old worker
rm -rf worker
# create a safe temporary directory and fail fast if it cannot be created
tmp_dir=$(mktemp -d -t fishtest-worker-XXXXXX) || { echo "Failed to create temporary directory" >&2; exit 1; }
# ensure we clean up the temp dir on any exit (success or failure)
cleanup() { [[ -n "$tmp_dir" && -d "$tmp_dir" ]] && rm -rf "$tmp_dir"; }
trap cleanup EXIT
pushd "$tmp_dir"
# download fishtest sources reliably (follow redirects, retry transient failures, time out if stuck)
if ! curl -L --fail --retry 5 --retry-delay 2 --retry-connrefused --connect-timeout 15 --max-time 600 -o master.zip \
  https://github.com/official-stockfish/fishtest/archive/master.zip; then
  echo "Error: failed to download fishtest archive" >&2
  exit 1
fi
if [[ ! -s master.zip ]]; then
  echo "Error: downloaded archive is missing or empty" >&2
  exit 1
fi
if [[ "$(head -c 4 master.zip)" != $'PK\003\004' ]]; then
  echo "Error: downloaded file is not a valid zip archive" >&2
  exit 1
fi
unzip master.zip "fishtest-master/worker/**"
pushd fishtest-master/worker
# setup a virtual environment
python3.exe -m venv "env"
env/bin/python3.exe -m pip install --upgrade pip setuptools wheel
env/bin/python3.exe -m pip install requests
# write fishtest.cfg
env/bin/python3.exe worker.py "$usr_name" "$usr_pwd" --concurrency "$n_cores" --only_config --no_validation && echo "Successfully set the concurrency value" || echo "Error: restart the script setting a proper concurrency value"

cat << EOF >> fishtest.cmd
@echo off
set PATH=C:\tools\msys64\mingw64\bin;C:\tools\msys64\usr\bin;%PATH%

env\bin\python3.exe -i worker.py
EOF

popd && popd
mv $tmp_dir/fishtest-master/worker .
