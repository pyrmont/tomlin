    # . bin/activate.fish
    if set -q _OLD_JANET_PATH
      echo 'An environment is already active, please run `deactivate` first.'
      return
    else
      set -gx _OLD_JANET_PATH "$JANET_PATH"
      set -gx _OLD_JANET_HISTFILE "$JANET_HISTFILE"
      set -gx _OLD_PATH "$PATH"
      set -gx _OLD_PS1 "$PS1"
      set -gx JANET_PATH "/home/cass/dev/contrib/tomlin/venv"
      set -gx JANET_VIRTUAL_ENV "venv"
      set -gx JANET_HISTFILE "/home/cass/dev/contrib/tomlin/venv/repl_history.jdn"
      set -gx PATH "$JANET_PATH"/bin "$PATH"

      function deactivate -d "Exit Janet environment"
        set -gx PATH "$_OLD_PATH"

        if test -n "$_OLD_JANET_PATH"
          set -gx JANET_PATH "$_OLD_JANET_PATH"
        else
          set -e JANET_PATH;
        end

        if test -n "$_OLD_JANET_HISTFILE"
          set -gx JANET_HISTFILE "$_OLD_JANET_HISTFILE"
        else
          set -e JANET_HISTFILE
        end

        set -e JANET_VIRTUAL_ENV

        if test -n "$_OLD_FISH_PROMPT_OVERRIDE"
            functions -e fish_prompt
            functions -c _old_fish_prompt fish_prompt
            functions -e _old_fish_prompt
        end
        set -e _OLD_FISH_PROMPT_OVERRIDE

        set -gx PS1 "$_OLD_PS1"
        set -e _OLD_JANET_PATH
        set -e _OLD_JANET_HISTFILE
        set -e _OLD_PATH
        set -e _OLD_PS1
        functions -e deactivate
      end

      if not set -q JANET_ENV_DISABLE_PROMPT
        # save the current fish prompt
        functions -c fish_prompt _old_fish_prompt

        function fish_prompt
          # save the old return status
          set -l old_status $status

          # Output the venv prompt; color taken from the blue from the Janet home page
          printf "%s%s%s" (set_color 076D96) "(venv) " (set_color normal)

          # restore return status
          echo "exit $old_status" | .

          # output the old prompt
          _old_fish_prompt
        end

        set -gx _OLD_FISH_PROMPT_OVERRIDE "venv"
      end
    end
    