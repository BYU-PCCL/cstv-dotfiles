#
# ~/.bash_profile
#

[[ -f ~/.bashrc ]] && . ~/.bashrc

if [[ ! ${DISPLAY} && ${XDG_VTNR} == 1 ]]; then
	exec startx
	sleep 2
	exit 1
fi
