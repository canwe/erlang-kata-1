-module(nsg_cluster_mgr).
-behaviour(gen_server).

-export([start_link/0,
         add_to_cluster/1,
         remove_from_cluster/1,
         get_nodes/0]).

-export([init/1,
         handle_info/2,
         handle_cast/2,
         handle_call/3,
         terminate/2,
         code_change/3]).

start_link() ->
    gen_server:start_link({local, ?MODULE}, ?MODULE, [], []).

add_to_cluster(Node) ->
    gen_server:call(?MODULE, {add, Node}).

remove_from_cluster(Node) ->
    gen_server:call(?MODULE, {remove, Node}).

get_nodes() ->
    gen_server:call(?MODULE, get_nodes).

init(_) ->
    erlang:send_after(5000, self(), check),
    {ok, #{nodes => sets:new()}}.

handle_info(check, #{nodes := Nodes} = State) ->
    do_cluster_check(sets:to_list(Nodes)),
    erlang:send_after(5000, self(), check),
    {noreply, State};
handle_info(_Info, State) ->
    {noreply, State}.

handle_cast(_Msg, State) ->
    {noreply, State}.

handle_call({add, Node}, _From, #{nodes := Nodes} = State) ->
    Nodes2 = sets:add_element(Node, Nodes),
    {reply, ok, State#{nodes => Nodes2}};
handle_call(get_nodes, _From, #{nodes := Nodes} = State) ->
    {reply, sets:to_list(Nodes), State};
handle_call(_Req, _From, State) ->
    {reply, ok, State}.

terminate(_Reason, _State) ->
    ok.

code_change(_OldVsn, State, _Extra) ->
    {ok, State}.

do_cluster_check(Nodes) ->
    [do_check_node(Node) || Node <- Nodes].

do_check_node(Node) ->
    case rpc:call(Node, erlang, self, [], 1000) of
        Result ->
            lager:info("Check result: ~p ~p", [Node, Result])
    end.
