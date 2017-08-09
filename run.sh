#!/bin/bash

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Function copied from https://github.com/openshift/origin/blob/release-1.4/images/ipfailover/keepalived/lib/utils.sh
function expand_ip_ranges() {
  local vips=${1:-""}
  local expandedset=()

  for iprange in $(echo "$vips" | sed 's/[^0-9\.\,-]//g' | tr "," " "); do
    local ip1=$(echo "$iprange" | awk '{print $1}' FS='-')
    local ip2=$(echo "$iprange" | awk '{print $2}' FS='-')
    if [ -z "$ip2" ]; then
      expandedset=(${expandedset[@]} "$ip1")
    else
      local base=$(echo "$ip1" | cut -f 1-3 -d '.')
      local start=$(echo "$ip1" | awk '{print $NF}' FS='.')
      local end=$(echo "$ip2" | awk '{print $NF}' FS='.')
      for n in `seq $start $end`; do
        expandedset=(${expandedset[@]} "${base}.$n")
      done
    fi
  done

  echo "${expandedset[@]}"
}

DEFAULT_INTERFACE=$(ip route get 8.8.8.8 | awk '/dev/ { f=NR }; f && (NR-1 == f)' RS=" ")

export ID_OFFSET=$(( ${OPENSHIFT_HA_VRRP_ID_OFFSET:-0} + 1 ))
export VIPS="$(expand_ip_ranges "${OPENSHIFT_HA_VIRTUAL_IPS}" | tr ' ' '\n')"
export VIP_INTERFACE="${OPENSHIFT_HA_NETWORK_INTERFACE:-${DEFAULT_INTERFACE}}"

envsubst <${SCRIPT_DIR}/keepalived.conf.tmpl >/etc/keepalived/keepalived.conf

source /etc/sysconfig/keepalived

exec /usr/sbin/keepalived $KEEPALIVED_OPTIONS -n --log-console
