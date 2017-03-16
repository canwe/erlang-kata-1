-module(nsg_channel_sup).
-behaviour(supervisor).

-export([start_link/0,
         start_channel/1,
         init/1]).

start_link() ->
    supervisor:start_link({local, ?MODULE}, ?MODULE, []).

start_channel(Name) ->
    supervisor:start_child(?MODULE, [Name]).

init(_Args) ->
    {ok, {#{strategy => simple_one_for_one,
            intensity => 5,
            period => 1000},
          [child(nsg_channel, [])]}
         }.

child(Module, Args) ->
    #{id => Module,
      start => {Module, start_link, Args},
      restart => temporary,
      shutdown => brutal_kill,
      type => worker,
      modules => []}.
