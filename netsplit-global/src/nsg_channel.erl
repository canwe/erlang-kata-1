-module(nsg_channel).
-behaviour(gen_server).

-export([start_link/1,
         get_channel/1]).

-export([init/1,
         handle_info/2,
         handle_cast/2,
         handle_call/3,
         terminate/2,
         code_change/3]).

start_link(Name) ->
    gen_server:start_link(?MODULE, [Name], []).

get_channel(Name) ->
    case global:whereis_name({channel, Name}) of
        undefined ->
            {ok, Pid} = nsg_channel_sup:start_channel(Name),
            global:register_name({channel, Name}, Pid),
            Pid;
        Pid ->
            Pid
    end.

init([Name]) ->
    {ok, #{name => Name}}.

handle_info(_Info, State) ->
    {noreply, State}.

handle_cast(_Msg, State) ->
    {noreply, State}.

handle_call(_Req, _From, State) ->
    {reply, ok, State}.

terminate(_Reason, _State) ->
    ok.

code_change(_OldVsn, State, _Extra) ->
    {ok, State}.
