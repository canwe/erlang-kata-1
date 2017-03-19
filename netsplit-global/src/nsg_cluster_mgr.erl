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
    erlang:send_after(1000, self(), check),
    {ok, #{nodes => sets:add_element(node(), sets:new())}}.

handle_info(check, #{nodes := Nodes} = State) ->
    NewNodes = sync(sets:to_list(Nodes)),
    Nodes2 = sets:union(Nodes, sets:from_list(NewNodes)),
    erlang:send_after(10000, self(), check),
    {noreply, State#{nodes => Nodes2}};
handle_info(_Info, State) ->
    {noreply, State}.

handle_cast(_Msg, State) ->
    {noreply, State}.

handle_call({add, Node}, _From, #{nodes := Nodes} = State) ->
    Nodes2 = sets:add_element(Node, Nodes),
    {reply, ok, State#{nodes => Nodes2}};
handle_call({remove, Node}, _From, #{nodes := Nodes} = State) ->
    Nodes2 = sets:del_element(Node, Nodes),
    {reply, ok, State#{nodes => Nodes2}};
handle_call(get_nodes, _From, #{nodes := Nodes} = State) ->
    {reply, sets:to_list(Nodes), State};
handle_call(_Req, _From, State) ->
    {reply, ok, State}.

terminate(_Reason, _State) ->
    ok.

code_change(_OldVsn, State, _Extra) ->
    {ok, State}.

sync(Nodes) ->
    %% Get the nodes from all nodes and union them
    NewNodes = sync(Nodes, Nodes, []),
    case NewNodes of
        [] ->
            ok;
        _ ->
            lager:info("New nodes ~p", [NewNodes])
    end,
    NewNodes.

sync([], _AllNodes, NewNodes) ->
    NewNodes;
sync([Node | Rest], AllNodes, NewNodes) when Node =:= node() ->
    sync(Rest, AllNodes, NewNodes);
sync([Node | Rest], AllNodes, NewNodes) ->
    case do_check_node(Node) of
        error ->
            sync(Rest, AllNodes, NewNodes);
        RemoteNodes ->
            RemoteNew = RemoteNodes -- AllNodes,
            NewNodes2 = lists:usort(NewNodes ++ RemoteNew),
            %% If this node is not in the remote nodes, let us add it
            case lists:member(node(), RemoteNodes) of
                false ->
                    rpc:call(Node, nsg_cluster_mgr, add_to_cluster, [node()]);
                true ->
                    ok
            end,
            sync(Rest, AllNodes, NewNodes2)
    end.

do_check_node(Node) ->
    case rpc:call(Node, nsg_cluster_mgr, get_nodes, [], 1000) of
        {badrpc, Reason} ->
            lager:warning("Cannot reach ~p: ~p", [Node, Reason]),
            error;
        Result ->
            lager:info("Check result: ~p ~p", [Node, Result]),
            Result
    end.
