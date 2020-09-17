export PATH=/usr/local/bin:/usr/local/sbin:/usr/bin:/usr/sbin:/bin:/sbin:$PATH
obp_opts=

xhost +
xset -dpms
xset s off
xset m 5/2 0

[[ -f ~/.config/openbox/lxde-rc.xml ]] && opb_opts="--config-file ~/.config/openbox/lxde-rc.xml"
openbox $opb_opts &

/opt/galauncher/startfe.sh
