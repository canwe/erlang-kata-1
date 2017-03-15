-module(mylib_srv).

-export([start_link/0,
         init/1,
         handle_call/3]).

start_link() ->
    gen_server:start_link({local, ?MODULE}, ?MODULE, [], []).

init(_) ->
    {ok, undefined}.

handle_call(_Msg, _From, State) ->
    timer:sleep(10000),
    {reply, ok, State}.

