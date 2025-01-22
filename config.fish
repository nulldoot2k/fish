# https://arthurpedroti.com.br/setup-fish-starship-nvm-ubuntu-linux-wsl2/
if status is-interactive
  set -gx EDITOR nvim
  set -gx PATH $PATH ~/.fnm ~/.yarn/bin ~/.composer/vendor/bin
  set -gx PATH $PATH /usr/local/go-1.23.2/bin

  if not set -q TMUX
      set session_name (openssl rand -hex 2)
      exec tmux new-session -A -s $session_name
      exec tmux attach-session -t $session_name
  end
  for file in ~/.config/fish/functions/*.fish
      source $file
  end
end
