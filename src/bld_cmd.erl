%% Copyright (c) 2015-2016, Grzegorz Junka
%% All rights reserved.
%%
%% Redistribution and use in source and binary forms, with or without
%% modification, are permitted provided that the following conditions are met:
%%
%% * Redistributions of source code must retain the above copyright notice,
%%   this list of conditions and the following disclaimer.
%% * Redistributions in binary form must reproduce the above copyright notice,
%%   this list of conditions and the following disclaimer in the documentation
%%   and/or other materials provided with the distribution.
%%
%% THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
%% AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
%% IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
%% ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
%% LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
%% CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
%% SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
%% INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
%% CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
%% ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE,
%% EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

-module(bld_cmd).

-export([
         git_branch/1,
         git_status/1,
         git_clone/3,
         rm_rf/1
        ]).

%%%-----------------------------------------------------------------------------
%%% Copied from https://github.com/yoonka/yolf.git
-export([is_cmd/1]).

is_cmd(Bin) ->
    case cmd(<< <<"which ">>/binary, Bin/binary >>) of
        {0, _} -> true;
        _ -> false
    end.

cmd(Command) ->
    Args = [binary, stderr_to_stdout, exit_status, hide, {line, 2048}],
    Port = open_port({spawn, Command}, Args),
    get_data(Port, {<<>>, []}).

get_data(Port, {Line, Lines}) ->
    receive
        {Port, {data, {eol, Bytes}}} ->
            NewLine = <<Line/binary, Bytes/binary>>,
            get_data(Port, {<<>>, [NewLine | Lines]});
        {Port, {data, {noeol, Bytes}}} ->
            get_data(Port, {<<Line/binary, Bytes/binary>>, Lines});
        {Port, {exit_status, Code}} ->
            {Code, lists:reverse(Lines)};
        Any ->
            {2, [<<"Error: Unhandled message from port!">>,
                binary:list_to_bin(io_lib:format(<<"~p">>, [Any]))
            ]}
    end.

%%% Copied from https://github.com/yoonka/yolf.git
%%%-----------------------------------------------------------------------------

execute_in(Path, Cmd) ->
    {ok, Cwd} = file:get_cwd(),
    file:set_cwd(filename:join(Cwd, Path)),
    Res = cmd(Cmd),
    file:set_cwd(Cwd),
    Res.

git_branch(Path) ->
    case execute_in(Path, <<"git symbolic-ref -q HEAD">>) of
        {0, [Res]} -> {0, lists:last(filename:split(Res))};
        Err -> Err
    end.

git_cmd(Path, Cmd) ->
    << <<"git --git-dir=\"">>/binary, Path/binary,
       <<"/.git\" --work-tree=\"">>/binary, Path/binary,
       <<"/\" ">>/binary, Cmd/binary >>.

git_status(Path) ->
    case filelib:is_dir(Path) of
        false -> false;
        true -> cmd(git_cmd(Path, <<"status --porcelain">>))
    end.

git_clone(Path, Tag, Clone) ->
    Cmd = << <<"git clone -q -b ">>/binary, Tag/binary, <<" ">>/binary,
             Clone/binary, <<" ">>/binary, Path/binary >>,
    cmd(Cmd).

rm_rf(Path) ->
    cmd(<< <<"rm -rf \"">>/binary, Path/binary, <<"\"">>/binary >>).
