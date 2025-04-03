#!/usr/bin/env bash
# shellcheck source=../../../framework/bootstrap.sh
#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#

#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#

#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#

###
# 如果 Jenkins 端口被占用
# 修改 /lib/systemd/system/jenkins.service 文件,然后重启即可
##
function radp_omg_jenkins_install() {
  if command -v jenkins >/dev/null 2>&1; then
    radp_log_info "jenkins already installed"
    return 0
  fi
  case "$g_guest_distro_pkg" in
  apt | apt-get)
    if ! command -v java >/dev/null 2>&1; then
      radp_log_error "Jenkins need JDK, please install JDK first"
      return 1
    fi
    $g_sudo wget -O /usr/share/keyrings/jenkins-keyring.asc \
      https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key
    echo "deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc]" \
      https://pkg.jenkins.io/debian-stable binary/ | sudo tee \
      /etc/apt/sources.list.d/jenkins.list >/dev/null
    $g_sudo apt-get update
#    $g_sudo apt install fontconfig openjdk-17-jre
    $g_sudo apt-get install jenkins || return 1
    $g_sudo systemctl start jenkins || {
      radp_log_error "如果启动失败,一般都是JDK版本问题, see https://www.jenkins.io/doc/book/platform-information/support-policy-java/"
      return 1
    }
    $g_sudo systemctl enable jenkins || return 1
    $g_sudo systemctl status jenkins
    ;;
  dnf)
    if ! command -v java >/dev/null 2>&1; then
      radp_log_error "Jenkins need JDK, please install JDK first"
      return 1
    fi
    sudo wget -O /etc/yum.repos.d/jenkins.repo \
      https://pkg.jenkins.io/redhat-stable/jenkins.repo
    sudo rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io-2023.key
    sudo dnf upgrade
    # Add required dependencies for the jenkins package
#    sudo dnf install fontconfig java-17-openjdk
    sudo dnf install jenkins
    sudo systemctl daemon-reload
    $g_sudo systemctl start jenkins || {
      radp_log_error "如果启动失败,一般都是JDK版本问题, see https://www.jenkins.io/doc/book/platform-information/support-policy-java/"
      return 1
    }
    $g_sudo systemctl enable jenkins || return 1
    $g_sudo systemctl status jenkins
    ;;
  *)
    radp_log_error "Not implemented on current os."
    return 1
    ;;
  esac
}
