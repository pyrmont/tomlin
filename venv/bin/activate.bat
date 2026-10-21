@rem bin\activate.bat
@if defined JANET_VIRTUAL_ENV (
    @echo An environment is already active, please run `deactivate` first.
    @exit /b 1
)
@set _OLD_JANET_PATH=%JANET_PATH%
@set _OLD_JANET_HISTFILE=%JANET_HISTFILE%
@set _OLD_PATH=%PATH%
@set _OLD_PROMPT=%PROMPT%
@set JANET_PATH=/home/cass/dev/contrib/tomlin/venv
@set JANET_VIRTUAL_ENV=venv
@set JANET_HISTFILE=/home/cass/dev/contrib/tomlin/venv\repl_history.jdn
@set PATH=%JANET_PATH%\bin;%PATH%
@set PROMPT=(venv) %PROMPT%