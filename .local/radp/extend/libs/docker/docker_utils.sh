#!/usr/bin/env bash
# shellcheck source=../../../framework/bootstrap.sh
#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#

function radp_docker_check_if_container_exists() {
  docker ps -a --format '{{.Names}}' | grep -wq "$1"
}