#
# /etc/bash.bashrc
#

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

#PS1='\e[0;41m \e[0;42m \e[48;5;21m \e[m[\u@\h \W]\$ '
#PS1='\[\033[48;2;173;28;28;249m\] \[\033[48;2;69;152;48;249m\] \[\033[48;2;35;62;139;249m\] \e[m[\u@\h \W]\$ '
#PS1="\[\e[48;2;250;40;40;249m\] \[\e[0m\]\[\e[48;2;100;220;70;249m\] \[\e[0m\]\[\e[48;2;50;90;200;249m\] \[\e[0m\][\u@\h \W]\$ "
PS1="\[\e[48;2;250;40;40;249m\] \[\e[0m\]\[\e[48;2;100;220;70;249m\] \[\e[0m\]\[\e[48;2;50;90;200;249m\] \[\e[0m\][\u@\h \W]$ "


case ${TERM} in
  Eterm*|alacritty*|aterm*|foot*|gnome*|konsole*|kterm*|putty*|rxvt*|tmux*|xterm*)
    PROMPT_COMMAND+=('printf "\033]0;%s@%s:%s\007" "${USER}" "${HOSTNAME%%.*}" "${PWD/#$HOME/\~}"')

    ;;
  screen*)
    PROMPT_COMMAND+=('printf "\033_%s@%s:%s\033\\" "${USER}" "${HOSTNAME%%.*}" "${PWD/#$HOME/\~}"')
    ;;
esac

if [[ -r /usr/share/bash-completion/bash_completion ]]; then
  . /usr/share/bash-completion/bash_completion
fi
