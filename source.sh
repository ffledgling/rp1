#!/bin/bash


L1_NAME="n4-ajs-1"
L2_NAME="nestedvm"

L1_IP="192.168.122.33"
L2_IP="192.168.123.30"

L0_PERF_BIN="/usr/bin/perf"
L1_PERF_BIN="/home/sanidhya/manually-installed/bin/perf-4.16.g0adb32"

VBENCH_ROOT="~/vm-scalability/bench"


error() {
  echo "ERROR: $@"
  return 42
}

audible-alert() {
  for i in {1..10}
  do
    echo -ne "\a"
    sleep 0.2
  done
}

require-args() {
  if [[ $2 -lt $1 ]]; then
    error "Required at $1 arguments, only $2 give"
  fi
}

# We expect this same file to be in L1, because it avoids a lot of nasty nested
# quoting, command passing and we don't have to create bash functions on the
# fly... just not worth it at the moment.
PATH_TO_SOURCE_IN_L1="/home/sanidhya/repos/rp1/source.sh"

vmip() {
  vmipaddr=$(virsh net-dhcp-leases default | grep "$1" | awk '{print $5}')
  vmipaddr=${vmipaddr%/*}
  echo $vmipaddr
}

vmls() {
  virsh list --all
}

gen-flame-from-perf() {
# Steps from https://github.com/brendangregg/FlameGraph
  _outfile="$1"
  _outfile="${_outfile:=out.svg}"
  _infile="$2"
  _flags=""
  if [[ "${_infile}" != "" ]]; then
    flags="${flags} -i ${_infile}"
  fi
  # Intentionally unquoted so that flags expand.
  perf script ${flags} > out.perf
  stackcollapse-perf.pl out.perf > out.folded
  flamegraph.pl out.folded > "${_outfile}"
}

ensure-domain-running() {
  dom_name="$1"
  dom_ip="$2"
  dom_state="$(virsh domstate "${dom_name}")"

  if ! [[ "${dom_state}" == *running* ]]; then
    virsh start "${dom_name}"
    if [[ $? -ne 0 ]]; then error "Could not start domain"; fi
    # Give the machine time to boot up and ssh to come up
    while ! ssh sanidhya@${dom_ip} 'echo "ssh started"'; do sleep 2; done
    # We wait for libvirtd to come up after sshd is started, this can take time... :/
    sleep 10
  fi
}

run-in-lx() {
  dom_name="$1"
  dom_ip="$2"
  cmd="$3"

  ensure-domain-running "${dom_name}" "${dom_ip}"
  ssh sanidhya@${dom_ip} "${cmd}"
}

run-in-l1() {
  #ensure-domain-running "${L1_NAME}"
  #ssh sanidhya@${L1_IP} "$1"
  run-in-lx "${L1_NAME}" "${L1_IP}" "$1"
}

run-in-l2() {
  cmd="source ${PATH_TO_SOURCE_IN_L1}"
  cmd="${cmd} ; run-in-lx ${L2_NAME} ${L2_IP} \"$1\""
  run-in-l1 "${cmd}"
}

get-domain-pid() {
  ps aux | grep qemu-system | grep "$1" | awk '{print $2}'
}

perf-l2-from-l0() {
  require-args 1 $# || return 42
set -x

  APP="$1"
  NUM_CORES="$2" # optional
  NUM_CORES="${NUM_CORES:-192}" # defualt to 192 cores
  ts=$(date '+%Y%m%d%H%M%S')
  perf_data="/dev/shm/perf.data.${APP}.${NUM_CORES}.${ts}"

  # We need to ensure L1 and L2 are running, the run-in command makes sure of
  # that.
  # We need to ensure tmpfs mount exists
  run-in-l2 "cd ~/vm-scalability/bench/ ; sudo ./mkmounts tmpfs-separate"

  dpid=$(get-domain-pid "${L1_NAME}")

  if [[ "$dpid" == "" ]]; then error "Could not find qemu pid"; fi

  # Start perf
  sudo ${L0_PERF_BIN} record -F 100 -a --call-graph dwarf -o ${perf_data} -p ${dpid} &> /tmp/perf.log &
  perf_pid=$!

  # run benchmark
  #run-in-l2 "cd ~/vm-scalability/bench/ ; sudo ./mkmounts tmpfs-separate ; ./config.py -d -c ${NUM_CORES} ${APP} ; sudo poweroff"
  run-in-l2 "cd ~/vm-scalability/bench/ ; ./config.py -d -c ${NUM_CORES} ${APP}"
  #run-in-l1 "sudo poweroff"

  # Instead of killing perf, we kill the process it's tracing, and then waiting
  # for it to gracefully finish

  ## Kill perf
  sudo kill -INT $perf_pid
  sleep 10
  wait
  # Shutdown the vm so that the next run is clean
  run-in-l2 "sudo poweroff"
  run-in-l1 "sudo poweroff"

  echo "perf.data written to ${perf_data}"

  set +x
}

perf-l2-from-l1() {
  error "This function is not yet implemented"
}

perf-l1-from-l0() {
  require-args 1 $# || return 42
set -x

  APP="$1"
  NUM_CORES="$2" # optional
  NUM_CORES="${NUM_CORES:-192}" # defualt to 192 cores
  ts=$(date '+%Y%m%d%H%M%S')
  perf_data="/dev/shm/perf.data.${APP}.${NUM_CORES}.${ts}"

  # We need to ensure L1 and L2 are running, the run-in command makes sure of
  # that.
  # We need to ensure tmpfs mount exists
  run-in-l1 "cd ~/vm-scalability/bench/ ; sudo ./mkmounts tmpfs-separate"

  dpid=$(get-domain-pid "${L1_NAME}")

  if [[ "$dpid" == "" ]]; then error "Could not find qemu pid"; fi

  # Start perf
  sudo ${L0_PERF_BIN} record -F 100 -a --call-graph dwarf -o ${perf_data} -p ${dpid} &> /tmp/perf.log &
  perf_pid=$!

  # run benchmark
  run-in-l1 "cd ~/vm-scalability/bench/ ; ./config.py -d -c ${NUM_CORES} ${APP}"

  ## Kill perf
  sudo kill -INT $perf_pid
  sleep 10
  wait
  # Shutdown the vm so that the next run is clean
  run-in-l1 "sudo poweroff"

  echo "perf.data written to ${perf_data}"

  set +x
}

benchmark-l2() {
  require-args 1 $# || return $?

  set -x

  APP="${1}"
  ts=$(date '+%Y%m%d%H%M%S')
  results_dir="/dev/shm/results.l2.${APP}.${ts}"

  # We add a little "cache warm" in case we have files and stuff we load/dump
  # The mount is required for psearchy, but doesn't hurt the other benchmarks, soo... *shrug*
  run-in-l2 "cd ~/vm-scalability/bench/ ; sudo ./mkmounts tmpfs-separate ; rm -rf results ; ./config.py -d -c 192 ${APP} ; ./config.py ${APP}"
  run-in-l1 "rsync -avz sanidhya@${L2_IP}:${VBENCH_ROOT}/results/ ${results_dir}"
  rsync -avz sanidhya@${L1_IP}:${results_dir}/ ${results_dir}
  mv ${results_dir} ~/scratch/

  # We shutdown the domain everytime because a bug in the numa code of the
  # benchmark fails to restore offline CPUs after the run which results in random
  # errors.
  run-in-l2 "sudo poweroff"
  run-in-l1 "sudo poweroff"

  echo "results are available in ${results_dir}"

  set +x
}

benchmark-l1() {
  require-args 1 $# || return $?

  set -x

  APP="${1}"
  ts=$(date '+%Y%m%d%H%M%S')
  results_dir="/dev/shm/results.l1.${APP}.${ts}"

  # We add a little "cache warm" in case we have files and stuff we load/dump
  # The mount is required for psearchy, but doesn't hurt the other benchmarks, soo... *shrug*
  run-in-l1 "cd ~/vm-scalability/bench/ ; sudo ./mkmounts tmpfs-separate  ; rm -rf results ; ./config.py -d -c 192 ${APP} ; ./config.py ${APP}"
  rsync -avz sanidhya@${L1_IP}:${VBENCH_ROOT}/results/ ${results_dir}
  mv ${results_dir} ~/scratch/

  # We shutdown the domain everytime because a bug in the numa code of the
  # benchmark fails to restore offline CPUs after the run which results in random
  # errors.
  run-in-l1 "sudo poweroff"

  echo "results are available in ${results_dir}"

  set +x
}

benchmark-both() {
  require-args 1 $# || return $?

  echo > benchmark-both.log
  for b in "$@"
  do
    echo "STARTING ${b} (L2)" >> benchmark-both.log
    time benchmark-l2 "${b}" | tee -a benchmark-both.log
    sleep 30 # wait for poweroff cleanly
    echo "STARTING ${b} (L1)" >> benchmark-both.log
    time benchmark-l1 "${b}" | tee -a benchmark-both.log
    echo "DONE ${b}" >> benchmark-both.log
  done
  audible-alert
}

_parse-perf-live() {
local FILE=$1

(cat ${FILE} | grep 'VM-EXIT' | sort | uniq | sed 's/^\s\+//' ;
cat ${FILE} | grep '+-' | awk '{a[$1]+=$2; b[$1]+=$3; c[$1]+=$4}END{for(i in a) print i,a[i],b[i],c[i]}' | sort -rn -k2 ) | column -t
}

perf-kvm-l2-from-l0() {
  require-args 1 $# || return 42
set -x

  APP="$1"
  NUM_CORES="$2" # optional
  NUM_CORES="${NUM_CORES:-192}" # defualt to 192 cores
  ts=$(date '+%Y%m%d%H%M%S')
  perf_data="/dev/shm/perf.data.guest.live.${APP}.${NUM_CORES}.${ts}"
  vmexit_data="/dev/shm/vmexits.${APP}.${NUM_CORES}.${ts}"
  results_dir="/dev/shm/results.l2.${APP}.${NUM_CORES}.${ts}"

  # We need to ensure L1 and L2 are running, the run-in command makes sure of
  # that.
  # We need to ensure tmpfs mount exists
  run-in-l2 "cd ~/vm-scalability/bench/ ; sudo ./mkmounts tmpfs-separate; rm -rf sanity/"

  dpid=$(get-domain-pid "${L1_NAME}")

  if [[ "$dpid" == "" ]]; then error "Could not find qemu pid"; fi

  # Start perf
  nohup sudo ${L0_PERF_BIN} kvm stat live -p ${dpid} &> ${perf_data} &
  perf_pid=$!

  # run benchmark
  run-in-l2 "cd ~/vm-scalability/bench/ ; ./config.py -d -c ${NUM_CORES} ${APP}"

  ## Kill perf
  sudo kill $perf_pid
  sleep 5
  sudo ps aux | grep perf
  sudo kill -9 $perf_pid
  sleep 5
  sudo pkill -9 perf
  wait $perf_pid

  # extract the throughput nunmbers
  run-in-l2 "ls /dev/shm/"
  run-in-l1 "rsync -avz sanidhya@${L2_IP}:${VBENCH_ROOT}/sanity/ ${results_dir}"
  rsync -avz sanidhya@${L1_IP}:${results_dir}/ ${results_dir}

  # Shutdown the vm so that the next run is clean
  run-in-l2 "sudo poweroff"
  run-in-l1 "sudo poweroff"

  _parse-perf-live ${perf_data} > ${vmexit_data}

  echo "Data written to ${perf_data}"

  set +x
}
