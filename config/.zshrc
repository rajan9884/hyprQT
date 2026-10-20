# ~/.zshrc — hyprQT dotfiles.
#
# Guarded tool inits: a missing tool is skipped silently, so the shell always
# starts clean even mid-install (nothing here may error under `set -e`).

# ── Prompt (starship, themed via ~/.config/theme) ──
if command -v starship >/dev/null 2>&1; then eval "$(starship init zsh)"; fi

# Hyprland launches GUI apps with cwd=/ — never start an interactive shell at /.
[[ "$PWD" == "/" ]] && cd "$HOME" >/dev/null 2>&1 || true

# ── Aliases ──
alias ff='nvim $(fzf -m --preview="bat --color=always {}")'
alias ffd='rm -rf $(fzf -m --preview="bat --color=always {}")'
alias zed='zeditor'
alias cd='z'
alias osd='bash delete-opencode-sessions.sh'
alias pi-session-del='bash delete-pi-sessions.sh'

# Monochrome eza
export EZA_COLORS="uu=bright-black:gu=bright-black:da=bright-black:ur=white:uw=bright-black:ux=white:ue=bright-black:gr=bright-black:gw=bright-black:gx=white:tr=bright-black:fi=white:di=bright-white:ln=bright-black:pi=bright-black:so=bright-black:bd=bright-black:cd=bright-black:or=bright-black:mi=bright-black:ex=white"

alias ls='eza --icons=auto'
alias ll='eza -lah --icons=auto --git'
alias la='eza -a --icons=auto'
alias lt='eza --tree --icons=auto'

# Directories
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'

# Dual-GitHub helpers: git-work / git-personal / git-whoami
[ -f "$HOME/.config/shell/git-accounts.sh" ] && source "$HOME/.config/shell/git-accounts.sh"

# ── Editor + fzf ──
export EDITOR="nvim" VISUAL="nvim"
export FZF_DEFAULT_OPTS="--height 90% --reverse --border"

# ── Speed tools (zoxide/fzf/yazi/atuin/direnv) ──
if command -v zoxide >/dev/null 2>&1; then eval "$(zoxide init zsh --cmd z)"; fi
if [ -f /usr/share/fzf/key-bindings.zsh ]; then source /usr/share/fzf/key-bindings.zsh; fi
if [ -f /usr/share/fzf/completion.zsh ]; then source /usr/share/fzf/completion.zsh; fi
# Atuin owns Ctrl-R; fzf keeps Ctrl-T + Alt-C.
if command -v atuin >/dev/null 2>&1; then eval "$(atuin init zsh --disable-up-arrow)"; fi
if command -v direnv >/dev/null 2>&1; then eval "$(direnv hook zsh)"; fi

# yazi: `y` cds into the directory you exit in
y() {
  local tmp="$(mktemp -t yazi-cwd.XXXXXX)"
  command yazi "$@" --cwd-file="$tmp"
  local cwd="$(cat -- "$tmp" 2>/dev/null)"
  rm -f -- "$tmp"
  [ -n "$cwd" ] && [ "$cwd" != "$PWD" ] && cd -- "$cwd"
}

# ~/.local/bin carries the repo helpers.
case ":$PATH:" in *":$HOME/.local/bin:"*) ;; *) export PATH="$HOME/.local/bin:$PATH";; esac

# Desktop info on login
command -v fastfetch >/dev/null 2>&1 && fastfetch

# --------------------------------------------------
# Completion
# --------------------------------------------------

autoload -Uz compinit
compinit

# Better completion menu
zstyle ':completion:*' menu select

# Case-insensitive matching
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'

# Completion colors — grayscale
zstyle ':completion:*' list-colors \
  '=(#b)*(=0)=38;5;250' \
  '=(#b)*(=1)=38;5;255' \
  '=(#b)*(=2)=38;5;245' \
  '=(#b)*(=3)=38;5;240'

# Autosuggestions — dark gray
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=8'

# --------------------------------------------------
# History
# --------------------------------------------------

HISTFILE="$HOME/.zsh_history"
HISTSIZE=100000
SAVEHIST=100000
setopt EXTENDED_HISTORY
setopt SHARE_HISTORY
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_FIND_NO_DUPS
setopt HIST_SAVE_NO_DUPS

source /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh

# Syntax highlighting (MUST be LAST plugin)
source /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

# Grayscale
ZSH_HIGHLIGHT_STYLES[command]='fg=white'
ZSH_HIGHLIGHT_STYLES[builtin]='fg=white'
ZSH_HIGHLIGHT_STYLES[function]='fg=white'
ZSH_HIGHLIGHT_STYLES[alias]='fg=white'
ZSH_HIGHLIGHT_STYLES[path]='fg=245'
ZSH_HIGHLIGHT_STYLES[comment]='fg=240'
ZSH_HIGHLIGHT_STYLES[unknown-token]='fg=245'

export PATH=/home/rj9884/.opencode/bin:$PATH

export PATH="/home/rj9884/.local/bin:$PATH"
# theme controller
theme() { python3 "$HOME/.config/theme/bin/theme.py" "$@"; }

# kilo
export PATH=/home/rj9884/.kilo/bin:$PATH
