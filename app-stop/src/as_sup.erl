-module(as_sup).
-behaviour(supervisor).

-export([start_link/0,
         init/1]).

start_link() ->
    supervisor:start_link({local, as_sup}, as_sup, []).

init(_Args) ->
    {ok, {#{startegy => one_for_one,
            intensity => 5,
            period => 1000},
          [child(as_service, [])
           %start_cowboy()
          ]}
         }.

child(Module, Args) ->
    #{id => Module,
      start => {Module, start_link, Args},
      restart => permanent,
      shutdown => brutal_kill,
      type => worker,
      modules => []}.

%child_sup(Module, Args) ->
%    Spec = child(Module, Args),
%    Spec#{shutdown => infinity,
%          type => supervisor}.
