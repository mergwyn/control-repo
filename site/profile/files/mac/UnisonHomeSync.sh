#!/bin/bash
LOCAL="${HOME}"
REMOTE="ssh://${LOGNAME}@foxtrot//home/${LOGNAME}"
ARGS="-silent -ui text"

if [[ $(pmset -g ps | head -1) =~ "AC Power" ]]; then
	/usr/local/bin/unison Home ${LOCAL} ${REMOTE} ${ARGS}
	#/usr/local/bin/unison Preferences ${LOCAL}/Library ${REMOTE}/Library ${ARGS}
fi
