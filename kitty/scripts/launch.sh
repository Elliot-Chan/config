#!/usr/bin/env bash
set -euo pipefail

exec kitty --single-instance --instance-group main "$@"
