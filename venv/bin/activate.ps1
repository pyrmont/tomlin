# . bin/activate.ps1
if ($env:JANET_VIRTUAL_ENV -ne $null) {
  Write-Host 'An environment is already active, please run `deactivate` first.'
  Exit 1;
}
$global:_OLD_JANET_PATH=$env:JANET_PATH
$global:_OLD_JANET_HISTFILE=$env:JANET_HISTFILE
$global:_OLD_PATH=$env:PATH
$env:JANET_PATH="/home/cass/dev/contrib/tomlin/venv"
$env:JANET_VIRTUAL_ENV="venv"
$env:JANET_HISTFILE="/home/cass/dev/contrib/tomlin/venv\repl_history.jdn"
$env:PATH=$env:JANET_PATH + "\bin;" + $env:PATH
$function:old_prompt = $function:prompt
function global:prompt {
  Write-Host "(venv) " -NoNewline
  & $function:old_prompt
}
function deactivate {
  $env:PATH=$global:_OLD_PATH
  $env:JANET_PATH=$global:_OLD_JANET_PATH
  $env:JANET_HISTFILE=$global:_OLD_JANET_HISTFILE
  Remove-Item env:\JANET_VIRTUAL_ENV
  Remove-Item function:\deactivate
  $function:prompt = $function:old_prompt
  Remove-Item function:\old_prompt
}