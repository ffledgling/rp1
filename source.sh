#!/bin/bash


L1_NAME="n4-ajs-1"
L2_NAME="nestedvm"

L1_IP="192.168.122.33"
L2_IP="192.168.123.30"

L0_PERF_BIN="/usr/bin/perf"
L1_PERF_BIN="/home/sanidhya/manually-installed/bin/perf-4.16.g0adb32"



error() {
  echo "ERROR: $@"
  return 42
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
  perf script > out.perf
  stackcollapse-perf.pl out.perf > out.folded
  flamegraph.pl out.folded > "${_outfile}"
}

ensure-domain-running() {
  dom_name="$1"
  dom_state="$(virsh domstate "${dom_name}")"

  if ! [[ "${dom_state}" == *running* ]]; then
    virsh start "${dom_name}"
    if [[ $? -ne 0 ]]; then error "Could not start domain"; fi
    # Give the machine time to boot up and ssh to come up
    sleep 30
  fi
}

run-in-lx() {
  dom_name="$1"
  dom_ip="$2"
  cmd="$3"

  ensure-domain-running "${dom_name}"
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
set -x

  APP="$1"
  NUM_CORES=80
  ts=$(date '+%Y%m%d%H%M%S')
  perf_data="/dev/shm/perf.data.${APP}.${NUM_CORES}.${ts}"

  # We need this because we want L1 running for it's PID
  ensure-domain-running "${L1_NAME}"
  dpid=$(get-domain-pid "${L1_NAME}")

  if [[ "$dpid" == "" ]]; then error "Could not find qemu pid"; fi

  # Start perf
  sudo ${L0_PERF_BIN} record -F 100 -a --call-graph dwarf -o ${perf_data} -p ${dpid} &> /tmp/perf.log &
  perf_pid=$!

  # run benchmark
  run-in-l2 "cd ~/vm-scalability/bench/ ; ./config.py -d -c ${NUM_CORES} ${APP} ; sudo poweroff"

  # Kill perf
  kill $perf_pid

  echo "perf.data written to ${perf_data}"

  set +x
}

perf-l2-from-l1() {
:
}
