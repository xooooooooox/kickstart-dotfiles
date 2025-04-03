_omg_alias_common(){
  alias cl=clear
  alias vi=vim
  alias nnvim='NVIM_APPNAME="nvim/kickstart-modular.nvim" nvim'
  alias nvim-kickstart='NVIM_APPNAME="nvim/kickstart-modular.nvim" nvim'
  alias lg=lazygit
  alias lc=colorls
}

_omg_alias_proxy(){
  local proxy_ip=${1:-127.0.0.1}

  alias disproxy='unset http_proxy https_proxy all_proxy'
  alias goproxy_clash="export https_proxy=http://${proxy_ip}:7890 http_proxy=http://${proxy_ip}:7890 all_proxy=socks5://${proxy_ip}:7891"
  alias goproxy_surge="export https_proxy=http://${proxy_ip}:6152 http_proxy=http://${proxy_ip}:6152 all_proxy=socks5://${proxy_ip}:6153"
}

_omg_alias_mac(){
  # 貌似 mas 不支持了已经
  alias masus='mas signout && mas signin register.2tv29@aleeas.com "mypassword"'
  alias mascn='mas signout && mas signin pay.kk@qq.com "mypassword"'
  alias mas?='mas account'
}

_omg_alias_docker() {
  alias	dcb='docker compose build'
  alias	dcdn='docker compose down'
  alias	dce='docker compose exec'
  alias	dck='docker compose kill'
  alias	dcl='docker compose logs'
  alias	dclF='docker compose logs -f --tail 0'
  alias	dclf='docker compose logs -f'
  alias	dco='docker compose'
  alias	dcps='docker compose ps'
  alias	dcpull='docker compose pull'
  alias	dcr='docker compose run'
  alias	dcrestart='docker compose restart'
  alias	dcrm='docker compose rm'
  alias	dcstart='docker compose start'
  alias	dcstop='docker compose stop'
  alias	dcup='docker compose up'
  alias	dcupb='docker compose up --build'
  alias	dcupd='docker compose up -d'
  alias	dcupdb='docker compose up -d --build'
}