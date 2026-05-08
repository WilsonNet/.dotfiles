# Created by newuser for 5.9

# Lines configured by zsh-newuser-install
HISTFILE=~/.histfile
HISTSIZE=1000
SAVEHIST=1000
bindkey -e
bindkey "^[[3~" delete-char
#
# Finally, make sure the terminal is in application mode, when zle is
# active. Only then are the values from $terminfo valid.
if (( ${+terminfo[smkx]} && ${+terminfo[rmkx]} )); then
	autoload -Uz add-zle-hook-widget
	function zle_application_mode_start { echoti smkx }
	function zle_application_mode_stop { echoti rmkx }
	add-zle-hook-widget -Uz zle-line-init zle_application_mode_start
	add-zle-hook-widget -Uz zle-line-finish zle_application_mode_stop
fi
# End of lines configured by zsh-newuser-install
# The following lines were added by compinstall
zstyle :compinstall filename '/home/wilsonn/.zshrc'

# End of lines added by compinstall
#
# Created by newuser for 5.9


#source ~/.zsh/zsh-autosuggestions/zsh-autosuggestions.zsh
source ~/.bash_aliases
export STARSHIP_CONFIG=~/.config/starship.toml
eval "$(starship init zsh)"

export PNPM_HOME="$HOME/.local/share/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac

# pnpm end
#THIS MUST BE AT THE END OF THE FILE FOR SDKMAN TO WORK!!!
export SDKMAN_DIR="$HOME/.sdkman"
[[ -s "$HOME/.sdkman/bin/sdkman-init.sh" ]] && source "$HOME/.sdkman/bin/sdkman-init.sh"

# pnpm
source ~/.zsh/zsh-autosuggestions/zsh-autosuggestions.zsh

# bun completions
[ -s "$HOME/.bun/_bun" ] && source "$HOME/.bun/_bun"

# Set up fzf key bindings and fuzzy completion
source <(fzf --zsh)

eval "$(mcfly init zsh)"
# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

alias invim='nvim $(fd --type dir | fzf)'

# opencode
export PATH=$HOME/.opencode/bin:$PATH

# asdf
export ASDF_DATA_DIR="$HOME/.asdf"
export PATH="$ASDF_DATA_DIR/shims:$PATH"
fpath=($ASDF_DATA_DIR/completions $fpath)
autoload -Uz compinit && compinit

if [[ -f ~/.zshrc.local ]]; then
    source ~/.zshrc.local
fi
