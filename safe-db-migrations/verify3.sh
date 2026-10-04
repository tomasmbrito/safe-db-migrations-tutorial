#!/bin/bash
T=/root/tutorial
[ "$(cat $T/state/ci_result 2>/dev/null)" = BLOCKED ] || exit 1
[ ! -f $T/db/migrations/20261002000000_rename_name_to_full_name.sql ] || exit 1
