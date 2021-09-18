#
# ~/.bash_profile
#

[[ -f ~/.bashrc ]] && . ~/.bashrc

if [[ ! ${DISPLAY} && ${XDG_VTNR} == 1 ]]; then
	startx -- -nocursor >/dev/null 2>&1
	sleep 2
	exit 1
fi
