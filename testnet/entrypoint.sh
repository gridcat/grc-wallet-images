#!/bin/bash

# Testnet wallet entrypoint. Same shape as the mainnet entrypoint —
# only the rpcport (47813 vs 47812) and the daemon binary differ.

echo "[INIT] Gridcoin Daemon configuration check (testnet)"

unset GRC_DATADIR
export GRC_DATADIR=/root/.GridcoinResearch/
echo "[INIT]   GRC_DATADIR=$GRC_DATADIR"

if [[ ! -d "$GRC_DATADIR" ]] ; then
  echo "[INIT]  Creating gridcoin datadir $GRC_DATADIR"
  mkdir -p "$GRC_DATADIR"
fi

if [[ ! -f "$GRC_DATADIR/gridcoinresearch.conf" ]] ; then
  touch "$GRC_DATADIR/gridcoinresearch.conf"
fi

# Resolve credentials with conf > env > random precedence. See the
# mainnet entrypoint for the rationale.
EXISTING_USER=$(grep -E '^rpcuser=' "$GRC_DATADIR/gridcoinresearch.conf" | head -n1 | cut -d= -f2-)
EXISTING_PASSWD=$(grep -E '^rpcpassword=' "$GRC_DATADIR/gridcoinresearch.conf" | head -n1 | cut -d= -f2-)

if [[ -n "$EXISTING_USER" ]]; then
  GRC_USERNAME="$EXISTING_USER"
  echo "[INIT]   GRC_USERNAME=$GRC_USERNAME (from conf)"
elif [[ -n "$GRC_USERNAME" ]]; then
  echo "[INIT]   GRC_USERNAME=$GRC_USERNAME (from env)"
else
  GRC_USERNAME=$(head /dev/urandom | tr -dc A-Za-z0-9 | head -c 32)
  echo "[INIT]   GRC_USERNAME=$GRC_USERNAME (newly generated)"
fi
export GRC_USERNAME

if [[ -n "$EXISTING_PASSWD" ]]; then
  GRC_PASSWD="$EXISTING_PASSWD"
  echo "[INIT]   GRC_PASSWD=$GRC_PASSWD (from conf)"
elif [[ -n "$GRC_PASSWD" ]]; then
  echo "[INIT]   GRC_PASSWD=$GRC_PASSWD (from env)"
else
  GRC_PASSWD=$(head /dev/urandom | tr -dc A-Za-z0-9 | head -c 32)
  echo "[INIT]   GRC_PASSWD=$GRC_PASSWD (newly generated)"
fi
export GRC_PASSWD

if [[ -z $(grep "rpcuser" $GRC_DATADIR/gridcoinresearch.conf) ]] ; then
  echo "[INIT]   SET:rpcuser=$GRC_USERNAME"
  echo "rpcuser=$GRC_USERNAME" | tee -a $GRC_DATADIR/gridcoinresearch.conf
fi
if [[ -z $(grep "rpcpassword" $GRC_DATADIR/gridcoinresearch.conf) ]] ; then
  echo "[INIT]   SET:rpcpassword=$GRC_PASSWD"
  echo "rpcpassword=$GRC_PASSWD" | tee -a $GRC_DATADIR/gridcoinresearch.conf
fi
if [[ -z $(grep "rpcport" $GRC_DATADIR/gridcoinresearch.conf) ]] ; then
  echo "[INIT]   SET:rpcport=47813"
  echo "rpcport=47813" | tee -a $GRC_DATADIR/gridcoinresearch.conf
fi
if [[ -z $(grep "rpcallowip" $GRC_DATADIR/gridcoinresearch.conf) ]] ; then
  echo "[INIT]   SET:rpcallowip=*"
  echo "rpcallowip=*" | tee -a $GRC_DATADIR/gridcoinresearch.conf
fi
if [[ -z $(grep "addnode" $GRC_DATADIR/gridcoinresearch.conf) ]] ; then
  echo "[INIT]  set nodes"
  cat /root/nodes.txt | tee -a $GRC_DATADIR/gridcoinresearch.conf
fi

echo "[INIT] Init completed"
echo "[INIT] Starting gridcoin daemon"

exec /usr/bin/gridcointestnetd
