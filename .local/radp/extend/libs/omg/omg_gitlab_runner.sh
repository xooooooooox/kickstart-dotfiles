#!/usr/bin/env bash
# shellcheck source=../../../framework/bootstrap.sh
#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#

#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#

#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#
function radp_omg_gitlab_runner_install() {
  if command -v gitlab-runner >/dev/null 2>&1; then
    radp_log_info "gitlab-runner already installed"
    return 0
  fi

  case "$g_guest_distro_pkg" in
    apt | apt-get)
      curl -L "https://packages.gitlab.com/install/repositories/runner/gitlab-runner/script.deb.sh" | sudo bash || {
        radp_log_error "Failed to Add the official GitLab repository"
        return 1
      }
      sudo apt install gitlab-runner -y || {
        radp_log_error "Failed to install gitlab-runner"
      }
      gitlab-runner status || {
        radp_log_error "Failed to run gitlab runner"
        return 1
      }
      ;;
    yum | dnf)
      curl -L "https://packages.gitlab.com/install/repositories/runner/gitlab-runner/script.rpm.sh" | sudo bash || {
        radp_log_error "Failed to Add the official GitLab repository"
        return 1
      }
      sudo yum install gitlab-runner -y || {
        radp_log_error "Failed to install gitlab-runner"
      }
      gitlab-runner status || {
        radp_log_error "Failed to run gitlab runner"
        return 1
      }
      ;;
    *)
      radp_log_error "Not implemented on current os."
      return 1
      ;;
  esac
}
