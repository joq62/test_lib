%%% -------------------------------------------------------------------
%%% @author  : Joq Erlang
%%% @doc: : 
%%% Created :
%%% Node end point   
%%% Creates and deletes Pods
%%% 
%%% API-kube: Interface 
%%% Pod consits beams from all services, app and app and sup erl.
%%% The setup of envs is
%%% -------------------------------------------------------------------
-module(basic).   
 
-export([start/0]).
%% --------------------------------------------------------------------
%% Include files
%% --------------------------------------------------------------------
-define(HostNames,["c100","c200","c202"]).
%-define(HostNames,["c100"]).
-define(C1,[{"c1_node1","c1_node1.dir","c1"},
	     {"c1_node2","c1_node2.dir","c1"},
	     {"c1_node3","c1_node3.dir","c1"},
	     {"c1_node4","c1_node4.dir","c1"}]).
%% --------------------------------------------------------------------
%% Function: available_hosts()
%% Description: Based on hosts.config file checks which hosts are avaible
%% Returns: List({HostId,Ip,SshPort,Uid,Pwd}
%% --------------------------------------------------------------------
start()->
    %% OBS Test node is hidden 
    ok=setup(),
    ok=application:start(test_lib),
    ok=single_test(),
    ok=single_cookie_test(),
%    ok=map_cookie_test(?HostNames,?C1),

%    ok=multi_cookie_test(),

%io:format("DBG: CreateBasicAppls~p~n",[{CreateBasicAppls,?MODULE,?FUNCTION_NAME,?LINE}]),
    io:format("TEST Ok, there you go! ~p~n",[{?MODULE,?FUNCTION_NAME,?LINE}]),
    init:stop(),
    ok.

%% --------------------------------------------------------------------
%% Function: available_hosts()
%% Description: Based on hosts.config file checks which hosts are avaible
%% Returns: List({HostId,Ip,SshPort,Uid,Pwd}
%% --------------------------------------------------------------------
single_test()->
    HostName="c100",
    NodeName="first_test",
    Node=list_to_atom(NodeName++"@"++HostName),
    NodeDir="first_test.dir",
    {ok,Node}=test_lib:create_basic_appls(HostName,NodeName,NodeDir),
  
    pong=rpc:call(Node,pod,ping,[]),
    pong=rpc:call(Node,common,ping,[]),
    pong=rpc:call(Node,sd,ping,[]),
    pong=rpc:call(Node,nodelog,ping,[]),
    io:format("SUBTEST Ok: ~p~n",[{?MODULE,?FUNCTION_NAME,?LINE}]),
    ok.
%% --------------------------------------------------------------------
%% Function: available_hosts()
%% Description: Based on hosts.config file checks which hosts are avaible
%% Returns: List({HostId,Ip,SshPort,Uid,Pwd}
%% -------------------------------------------------------------------

-define(NodeNameNodeDirCookie,[{"node1","node1.dir","node1"},
			       {"node2","node2.dir","node2"},
			       {"node3","node3.dir","node3"},
			       {"node4","node4.dir","node4"}]).

%% --------------------------------------------------------------------
%% Function: available_hosts()
%% Description: Based on hosts.config file checks which hosts are avaible
%% Returns: List({HostId,Ip,SshPort,Uid,Pwd}
%% -------------------------------------------------------------------

single_cookie_test()->
    LoadStartArgs=[{HostName,NodeName,NodeDir,Cookie}||HostName<-?HostNames,
							      {NodeName,NodeDir,Cookie}<-?NodeNameNodeDirCookie],  
  %  Result=[load_start(LoadStartArg)||LoadStartArg<-LoadStartArgs],
    Result=[test_lib:load_start_basic(LoadStartArg)||LoadStartArg<-LoadStartArgs],
    io:format("DBG: Result ~p~n",[{?MODULE,?FUNCTION_NAME}]),
    
    io:format("TEST OK! ~p~n",[{Result,?MODULE,?FUNCTION_NAME}]),
    ok.

load_start({HostName,NodeName,NodeDir,Cookie})->    
    true=erlang:set_cookie(node(),list_to_atom(Cookie)),
    Node=list_to_atom(NodeName++"@"++HostName),
    rpc:call(Node,init,stop,[]),
    timer:sleep(2000),
    PaArgs=" ",
    EnvArgs=" ",
    {ok,Node}=test_lib:create_basic_appls(HostName,NodeName,NodeDir,Cookie,PaArgs,EnvArgs),
   
    pong=rpc:call(Node,pod,ping,[]),
    pong=rpc:call(Node,common,ping,[]),
    pong=rpc:call(Node,sd,ping,[]),
    pong=rpc:call(Node,nodelog,ping,[]),
    io:format("SUBTEST Ok: ~p~n",[{HostName,Node,NodeName,Cookie,?MODULE,?FUNCTION_NAME,?LINE}]),
    {ok,Node,Cookie}.

%% --------------------------------------------------------------------
%% Function: available_hosts()
%% Description: Based on hosts.config file checks which hosts are avaible
%% Returns: List({HostId,Ip,SshPort,Uid,Pwd}
%% -------------------------------------------------------------------
map_cookie_test(HostNames,ClusterInfo)->
    F1 = fun map_load_start/2,
    F2 = fun load_start_result/3,
    L=[{HostName,NodeName,NodeDir,Cookie}||HostName<-HostNames,
							      {NodeName,NodeDir,Cookie}<-ClusterInfo],  
    Result=mapreduce:start(F1,F2,[],L),
    io:format("DBG: Result ~p~n",[{?MODULE,?FUNCTION_NAME}]),
    
    io:format("TEST OK! ~p~n",[{Result,?MODULE,?FUNCTION_NAME}]),
    ok.

map_load_start(Pid,{HostName,NodeName,NodeDir,Cookie})->    
    true=erlang:set_cookie(node(),list_to_atom(Cookie)),
    Node=list_to_atom(NodeName++"@"++HostName),
    rpc:call(Node,init,stop,[]),
    timer:sleep(2000),
    PaArgs=" ",
    EnvArgs=" ",
    {ok,Node}=test_lib:create_basic_appls(HostName,NodeName,NodeDir,Cookie,PaArgs,EnvArgs),
  
    pong=rpc:call(Node,pod,ping,[]),
    pong=rpc:call(Node,common,ping,[]),
    pong=rpc:call(Node,sd,ping,[]),
    pong=rpc:call(Node,nodelog,ping,[]),
    io:format("SUBTEST Ok: ~p~n",[{HostName,Node,NodeName,Cookie,?MODULE,?FUNCTION_NAME,?LINE}]),
    Pid!{ok,Node,Cookie,ls_result}.

load_start_result(ls_result,Vals,Acc)->
     [{Vals,ls_result}|Acc].
%% --------------------------------------------------------------------
%% Function: available_hosts()
%% Description: Based on hosts.config file checks which hosts are avaible
%% Returns: List({HostId,Ip,SshPort,Uid,Pwd}
%% --------------------------------------------------------------------

%% --------------------------------------------------------------------
%% Function: available_hosts()
%% Description: Based on hosts.config file checks which hosts are avaible
%% Returns: List({HostId,Ip,SshPort,Uid,Pwd}
%% --------------------------------------------------------------------


setup()->
  
    ok.
