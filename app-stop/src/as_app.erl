-module(as_app).
-behaviour(application).

-export([start/2,
         stop/1]).

start(_Type, _Args) ->
    Result = as_sup:start_link(),
    start_cowboy(),
    Result.

stop(_State) ->
    cowboy:stop_listener(as_http_listener).

start_cowboy() ->
    Dispatch = cowboy_router:compile([
        {'_', [
            {"/[...]", cowboy_static, {priv_dir, as, "html"}}
        ]}
    ]),
    cowboy:start_clear(as_http_listener, 5, [{port, 8080}],
                       #{env => #{dispatch => Dispatch}}).
