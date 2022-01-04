#!/usr/bin/env bash

set -e

source $SNAP/actions/common/utils.sh
CA_CERT=/snap/core18/current/etc/ssl/certs/ca-certificates.crt

read -ra ARGUMENTS <<< "$1"
argz=("${ARGUMENTS[@]/#/--}")

ARCH=$(arch)

# check if linkerd cli is already in the system.  Download if it doesn't exist.
if [ ! -f "${SNAP_DATA}/bin/linkerd" ]; then
  LINKERD_VERSION="${LINKERD_VERSION:-v2.9.4}"
  echo "Fetching Linkerd2 version $LINKERD_VERSION."
  run_with_sudo mkdir -p "$SNAP_DATA/bin"
  LINKERD_VERSION=$(echo $LINKERD_VERSION | sed 's/v//g')
  echo "$LINKERD_VERSION"
  run_with_sudo "${SNAP}/usr/bin/curl" -L http://defaultrepo:10001/microk8s/1.21/linkerd2-cli-stable-${LINKERD_VERSION}-linux-${ARCH} -o "$SNAP_DATA/bin/linkerd"
  run_with_sudo chmod uo+x "$SNAP_DATA/bin/linkerd"
fi

echo "Enabling Linkerd2"
# enable dns service
KUBECTL="$SNAP/kubectl --kubeconfig=${SNAP_DATA}/credentials/client.config"
"$SNAP/microk8s-enable.wrapper" dns
# Allow some time for the apiserver to start
sleep 5
${SNAP}/microk8s-status.wrapper --wait-ready --timeout 30 >/dev/null


"$SNAP_DATA/bin/linkerd" "--kubeconfig=$SNAP_DATA/credentials/client.config" install "${argz[@]}" | $KUBECTL apply -f -
echo "Linkerd is starting"
