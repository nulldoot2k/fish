# SSH FZF completion for Fish shell
# Place this in ~/.config/fish/config.fish

function __ssh_fzf_completion
    # Get current command line info
    set -l cmdline (commandline -b)
    set -l cursor_pos (commandline -C)
    
    # Only trigger for ssh commands
    if not string match -rq '^ssh(\s|$)' "$cmdline"
        # Not ssh command, use default tab completion
        commandline -f complete
        return
    end
    
    # Parse SSH config for hosts
    set -l ssh_config "$HOME/.ssh/config"
    if not test -f "$ssh_config"
        echo "SSH config file not found: $ssh_config"
        return
    end
    
    # Extract hosts from config
    set -l hosts
    set -l current_host ""
    set -l current_hostname ""
    set -l current_user ""
    set -l current_desc ""
    
    while read -la line
        set -l line_str (string join " " $line)
        
        # Skip empty lines and comments (except #_desc)
        if test -z "$line_str"
            # Process completed host block
            if test -n "$current_host"
                set -l display_hostname $current_hostname
                if test -z "$display_hostname"
                    set display_hostname $current_host
                end
                
                set -l display_user $current_user
                if test -z "$display_user"
                    set display_user "default"
                end
                
                set -l display_desc $current_desc
                if test -z "$display_desc"
                    set display_desc ""
                else
                    set display_desc "[$display_desc]"
                end
                
                # Skip wildcard hosts
                if not string match -q "*\**" "$current_host"
                    set hosts $hosts "$current_host|$display_hostname|$display_user|$display_desc"
                end
            end
            
            # Reset for next host block
            set current_host ""
            set current_hostname ""
            set current_user ""
            set current_desc ""
            continue
        end
        
        if string match -rq '^\s*#[^_]' "$line_str"
            continue
        end
        
        # Parse config lines
        set -l parts (string split -m 1 " " (string trim "$line_str"))
        if test (count $parts) -ge 2
            set -l key (string lower $parts[1])
            set -l value (string trim $parts[2])
            
            switch $key
                case "host"
                    set current_host (string split " " $value)[1]  # Take first host if multiple
                case "hostname"
                    set current_hostname $value
                case "user"
                    set current_user $value
                case "#_desc"
                    set current_desc $value
            end
        end
    end < "$ssh_config"
    
    # Don't forget the last host block
    if test -n "$current_host"
        set -l display_hostname $current_hostname
        if test -z "$display_hostname"
            set display_hostname $current_host
        end
        
        set -l display_user $current_user
        if test -z "$display_user"
            set display_user "default"
        end
        
        set -l display_desc $current_desc
        if test -z "$display_desc"
            set display_desc ""
        else
            set display_desc "[$display_desc]"
        end
        
        if not string match -q "*\**" "$current_host"
            set hosts $hosts "$current_host|$display_hostname|$display_user|$display_desc"
        end
    end
    
    if test (count $hosts) -eq 0
        echo "No SSH hosts found in config"
        return
    end
    
    # Prepare for fzf
    set -l header "Alias          Hostname       User       Description
-----          --------       ----       -----------"
    
    # Format hosts for display
    set -l formatted_hosts
    for host in $hosts
        set -l parts (string split "|" $host)
        set formatted_hosts $formatted_hosts (printf "%-14s %-14s %-10s %s" $parts[1] $parts[2] $parts[3] $parts[4])
    end
    
    # Use fzf to select
    set -l selected (printf "%s\n%s\n" "$header" (string join \n $formatted_hosts) | fzf \
        --height 40% \
        --border \
        --ansi \
        --reverse \
        --header-lines=2 \
        --prompt="SSH Remote > " \
        --preview='echo {} | awk "{print \$1}" | xargs -I {} ssh -G {} 2>/dev/null | grep -E "^(hostname|user|port|identityfile)" | column -t' \
        --preview-window=right:50% 2>/dev/tty)
    
    if test -n "$selected"
        set -l selected_host (echo "$selected" | awk '{print $1}')
        # Replace entire command line with ssh + selected host
        commandline -r "ssh $selected_host"
    end
    
    commandline -f repaint
end

# Custom key binding function
function fish_user_key_bindings
    # Store original tab binding
    set -g __original_tab_binding (bind --user | grep '^bind \\t ' | string replace 'bind \\t ' '')
    if test -z "$__original_tab_binding"
        set -g __original_tab_binding complete
    end
    
    # Bind tab to our custom function
    bind \t __ssh_fzf_completion
end

# Alternative function for manual use
function sshs
    commandline -r "ssh "
    __ssh_fzf_completion
end
