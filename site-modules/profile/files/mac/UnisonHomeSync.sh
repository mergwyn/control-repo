#!/bin/bash
LOCAL="${HOME}"
REMOTE="ssh://${LOGNAME}@foxtrot//home/${LOGNAME}"
ARGS="-silent -ui text -repeat watch -terse"

if [[ $(pmset -g ps | head -1) =~ "AC Power" ]]; then
  /opt/homebrew/bin/unison Home ${LOCAL} ${REMOTE} ${ARGS}
fi
