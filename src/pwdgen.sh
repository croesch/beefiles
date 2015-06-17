#!/bin/bash
apg -a 1 -M SNCL -m 20 -n 10

echo
echo "Without \\'\`\""
apg -a 1 -M SNCL -m 20 -n 10 -E \\\'\`\"
