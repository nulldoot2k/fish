# TMATE Functions

set TMATE_PAIR_NAME (whoami)-pair
set TMATE_SOCKET_LOCATION /tmp/tmate-pair.sock
set TMATE_TMUX_SESSION /tmp/tmate-tmux-session

function tmate-url
    if not test -e "$TMATE_SOCKET_LOCATION"
        echo "No active tmate session found. Please create one first using 'tmate-pair'."
        return 1
    end
    set url (tmate -S $TMATE_SOCKET_LOCATION display -p '#{tmate_ssh}')
    echo "$url" | tr -d '\n' | xclip -in -selection clipboard > /dev/null
    echo "Copied tmate url for $TMATE_PAIR_NAME:"
    echo "$url"
end

function tmate-pair
    set -e TMUX
    sleep 1

    if not test -e "$TMATE_SOCKET_LOCATION"
        tmate -a ~/.ssh/authorized_keys -S "$TMATE_SOCKET_LOCATION" -f "$HOME/.tmate.conf" new-session -d -s "$TMATE_PAIR_NAME"

        set url ""
        while test -z "$url"
            set url (tmate -S "$TMATE_SOCKET_LOCATION" display -p '#{tmate_ssh}')
        end
        tmate-url
        sleep 1

        set first_session (TMUX='' tmux list-sessions -F "#S" | head -n 1)
        if test -n "$first_session"
            echo $first_session > $TMATE_TMUX_SESSION
            tmate -S "$TMATE_SOCKET_LOCATION" send -t "$TMATE_PAIR_NAME" "TMUX='' tmux attach-session -t $first_session" ENTER
        end
    end

    tmate -S "$TMATE_SOCKET_LOCATION" attach-session -t "$TMATE_PAIR_NAME"
end

function tmate-unpair
    if test -e "$TMATE_SOCKET_LOCATION"
        if test -e "$TMATE_TMUX_SESSION"
            tmux detach -s (cat $TMATE_TMUX_SESSION)
            rm -f $TMATE_TMUX_SESSION
        end

        tmate -S "$TMATE_SOCKET_LOCATION" kill-session -t "$TMATE_PAIR_NAME"
        echo "Killed session $TMATE_PAIR_NAME"
        rm -f "$TMATE_SOCKET_LOCATION"
    else
        echo "No active tmate session found to kill."
    end
end
