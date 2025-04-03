# kickstart-dotfiles

## Install

### step1 Install yadm

```shell
curl -fLo /usr/local/bin/yadm https://github.com/yadm-dev/yadm/raw/master/yadm && chmod a+x /usr/local/bin/yadm
```

### step2 Setup yadm

**注意: 切换到非 root 用户, 比如 `x9x`**

```shell
su - x9x
yadm clone https://github.com/x9x/kickstart-dotfiles.git
```