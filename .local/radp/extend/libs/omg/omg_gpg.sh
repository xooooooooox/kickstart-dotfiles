#!/usr/bin/env bash
# shellcheck source=../../../framework/bootstrap.sh
#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#

#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#
function _install_gpg_from_source() {
  local tmpdir
  tmpdir=$(mktemp -d)
  pushd "$tmpdir" || return 1

  # Declare all libraries names
  local libgpg_error="libgpg-error-1.50"
  local libgcrypt="libgcrypt-1.11.0"
  local libassuan="libassuan-3.0.1"
  local libksba="libksba-1.6.7"
  local ntbtls="ntbtls-0.3.2"
  local npth="npth-1.7"
  local gnupg="gnupg-2.4.5"

  local libraries=("$libgpg_error" "$libgcrypt" "$libassuan" "$libksba" "$ntbtls" "$npth" "$gnupg")

  # Download libraries and signatures
  local library library_name
  for library in "${libraries[@]}"; do
    # Strip the version number from the library
    library_name=$(echo "$library" | egrep -o '^[a-z]+-?[a-z]+')
    curl https://www.gnupg.org/ftp/gcrypt/"$library_name"/"$library".tar.bz2 -o "$library".tar.bz2 || return 1
    curl https://www.gnupg.org/ftp/gcrypt/"$library_name"/"$library".tar.bz2.sig -o "$library".tar.bz2.sig || return 1
  done

  # Verify and untar downloads
  for library in "${libraries[@]}"; do
    # 从 GnuPG 公钥服务器导入公钥, 无法验证
    #    gpg --keyserver keyserver.ubuntu.com --recv-keys 4F25E3B6
    #    gpg --verify "$library".tar.bz2.sig "$library".tar.bz2 || return 1
    tar xjf "$library".tar.bz2
  done

  # Install everything
  for library in "${libraries[@]}"; do
    local configure_command
    if [[ "$library" =~ ^libgcrypt ]]; then
      # 解决 libgcrypt make 时会报错的问题
      configure_command="./configure --disable-asm"
    else
      configure_command="./configure"
    fi

    cd "$library" \
      && $configure_command \
      && make \
      && $g_sudo make install \
      && cd ../ || {
      radp_log_error "An error occurred while installing '$library'"
      return 1
    }
  done

  # Add path to the new gpg and run ldconfig
  echo "/usr/local/lib" | $g_sudo tee -a /etc/ld.so.conf.d/gpg2.conf
  $g_sudo ldconfig -v || return 1
  # Rename old gpg2 in case you need it
  sudo mv /usr/bin/gpg2 /usr/bin/gpg2_old
  # Symlink new gpg2
  sudo ln -s /usr/local/bin/gpg /usr/bin/gpg2
  popd || reutrn 1
  rm -rvf "$tmpdir"
}

# 安装高保本 gpg
# 因为低版本 <2.1 gpg 不支持 --with-keygrip, 无法提前缓存私钥密码
function _install_gpg() {
  case "$g_guest_distro_pkg" in
    dnf | apt-get)
      radp_os_pkg_install gpg || return 1
      ;;
    *)
      # 源码安装有点麻烦, 这里就不写了
      # see https://gnupg.org/howtos/card-howto/en/ch02.html
      # 因为在安装高版本 gpg 前,还需要源码安装很多其它的包
      _install_gpg_from_source || return 1
      ;;
  esac
}

function radp_omg_gpg_install() {
  radp_omg_pinentry_install
  if command -v gpg >/dev/null 2>&1; then
    local gpg_version required_version
    # 必须保证各设备间的GPG版本基本一致
    # 2.1.x, 2.2.x, 2.3.x 彼此之间都存在或多或少的加解密不兼容问题
    required_version=2.3
    gpg_version=$(gpg --version | head -n 1 | awk '{print $3}')
    if ! radp_utils_check_version_satisfied "$gpg_version" "$required_version"; then
      _install_gpg
    else
      radp_log_info "gpg already installed, and its version '$gpg_version' is greater than '$required_version'"
      return 0
    fi
  else
    _install_gpg
  fi
}

function radp_omg_pinentry_install() {
  if command -v pinentry >/dev/null 2>&1; then
    radp_log_info "pinentry already installed"
    return 0
  fi
  radp_os_pkg_install pinentry || return 1
  if [[ "$g_guest_distro_id" == "osx" ]]; then
    if ! command -v pinentry-mac >/dev/null 2>&1; then
      brew install pinentry-mac || return 1
    fi
  fi
}
