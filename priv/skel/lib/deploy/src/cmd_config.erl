-module(cmd_config).

-export([
         subfolders/0,
         key_replace/4,
         process_config/4
        ]).

subfolders() ->
    {ok,
     [<<"config/cert">>,
      <<"mnesia_backups">>]}.

key_replace(Base, Name, Offset, RunVars) ->
    {_, Host} = proplists:get_value(hostname, RunVars),

    {ok,
     [
      {<<"=INETS_IP=">>, <<"0.0.0.0">>},
      {<<"=INETS_PORT=">>, integer_to_list(8080 + Offset), [global]},
      {<<"=SERVICE_NAME=">>, Name},
      {<<"=HOSTNAME=">>, Host},
      {<<"=ROOT_DIR=">>, Base, [global]}
     ]}.

process_config(_App, _Dest, _CfgArgs, _Privs) ->
    false.
