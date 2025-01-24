# TMUX Functions

function tmux-clean
    if test -n "$TMUX"
        tmux kill-server
    end
end
