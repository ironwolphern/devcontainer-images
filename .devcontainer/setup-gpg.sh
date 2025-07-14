#!/bin/bash
export GPG_TTY=$(tty)
export GPG_AGENT_INFO=""
gpg-connect-agent killagent /bye 2>/dev/null
gpg-connect-agent /bye 2>/dev/null