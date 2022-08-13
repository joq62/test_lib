%%% -------------------------------------------------------------------
%%% Author  : uabjle
%%% Description : dbase using dets 
%%% 
%%% Created : 10 dec 2012
%%% -------------------------------------------------------------------
-module(test_misc).     
    
%% --------------------------------------------------------------------
%% Include files
%% --------------------------------------------------------------------

%%---------------------------------------------------------------------
%% Records for test
%%

%% --------------------------------------------------------------------
%-compile(export_all).

-export([
	 load_start_basic/4,
	 create_basic_appls/3,
	 create_basic_appls/6
	 ]).
%-define(BasicAppls,["common","sd","nodelog"]).
-define(BasicAppls,["pod"]).
%% ====================================================================
%% External functions
%% ====================================================================


load_start_basic(HostName,NodeName,NodeDir,Cookie)->
    true=erlang:set_cookie(node(),list_to_atom(Cookie)),
    Node=list_to_atom(NodeName++"@"++HostName),
    rpc:call(Node,init,stop,[]),
    timer:sleep(2000),
    PaArgs=" ",
    EnvArgs=" ",
    Reply=case create_basic_appls(HostName,NodeName,NodeDir,Cookie,PaArgs,EnvArgs) of
	      {error,Reason}->
		  {error,[Reason,?MODULE,?FUNCTION_NAME,?LINE]};
	      {ok,Node}->
		  Ping=[{error,[not_connected,Node,AppId]}||AppId<-?BasicAppls,
							    pong/=rpc:call(Node,list_to_atom(AppId),ping,[])],
		  case Ping of
		      []->
			  {ok,Node,Cookie};
		      ErrorList->
			  {error,[ErrorList,?MODULE,?FUNCTION_NAME,?LINE]}
		  end
	  end,
 
    io:format("Load_start Result ~p~n",[{Reply,?MODULE,?FUNCTION_NAME,?LINE}]),
    Reply.


%% --------------------------------------------------------------------
%% Function:start/0 
%% Description: Initiate the eunit tests, set upp needed processes etc
%% Returns: non
%% --------------------------------------------------------------------
create_basic_appls(HostName,NodeName,NodeDir)->
    Ip=config:host_local_ip(HostName),
    Port=config:host_ssh_port(HostName),
    Uid=config:host_uid(HostName),
    Passwd=config:host_passwd(HostName),
    TimeOut=7000,

    ssh_vm:delete_dir(HostName,NodeDir),
    {ok,NodeDir}=ssh_vm:create_dir(HostName,NodeDir),

    Reply=case ssh_vm:create(HostName,NodeName,
			 {Ip,Port,Uid,Passwd,TimeOut}) of
	       {error,Reason}->
		   {error,Reason};
	       {ok,Node}->
		  GitLoadStart=[git_load_start(Node,Appl,NodeDir)||Appl<-?BasicAppls],
		   CheckGitLoadStart=[{error,Reason}||{error,Reason}<-GitLoadStart],
		   case CheckGitLoadStart of
		       []->
			   {ok,Node};
		       Reason ->
			   {error,Reason}
		   end
	  end,
    Reply.

%% --------------------------------------------------------------------
%% Function:start/0 
%% Description: Initiate the eunit tests, set upp needed processes etc
%% Returns: non
%% --------------------------------------------------------------------
create_basic_appls(HostName,NodeName,NodeDir,Cookie,PaArgs,EnvArgs)->
    Ip=config:host_local_ip(HostName),
    Port=config:host_ssh_port(HostName),
    Uid=config:host_uid(HostName),
    Passwd=config:host_passwd(HostName),
    TimeOut=7000,
    
    ssh_vm:delete_dir(HostName,NodeDir),
    {ok,NodeDir}=ssh_vm:create_dir(HostName,NodeDir),
    
    Reply=case ssh_vm:create(HostName,NodeName,Cookie,PaArgs,EnvArgs,
				 {Ip,Port,Uid,Passwd,TimeOut}) of
	       {error,Reason}->
		   {error,Reason};
	       {ok,Node}->
		  GitLoadStart=[git_load_start(Node,Appl,NodeDir)||Appl<-?BasicAppls],
		   CheckGitLoadStart=[{error,Reason}||{error,Reason}<-GitLoadStart],
		   case CheckGitLoadStart of
		       []->
			   {ok,Node};
		       Reason ->
			   {error,Reason}
		   end
	  end,
    Reply.

%% --------------------------------------------------------------------
%% Function:start/0 
%% Description: Initiate the eunit tests, set upp needed processes etc
%% Returns: non
%% --------------------------------------------------------------------
git_load_start(Node,Appl,NodeDir)->
    DirToClone=filename:join(NodeDir,Appl),
%    io:format("DirToClone ~p~n",[{DirToClone,?MODULE,?FUNCTION_NAME,?LINE}]),
    GitPath=config:application_gitpath(Appl++".spec"),
    App=list_to_atom(Appl),
    Paths=[filename:join([NodeDir,Appl,"ebin"])],    
    Reply=case rpc:call(Node,os,cmd,["rm -rf "++DirToClone]) of
	      []->
		  case rpc:call(Node,file,make_dir,[DirToClone]) of
		      {error,Reason}->
			  {error,[Reason,?MODULE,?FUNCTION_NAME,?LINE]};
		      {badrpc,Reason}->
			  {error,[badrpc,Reason,?MODULE,?FUNCTION_NAME,?LINE]};
		      ok->
			  case rpc:call(Node,filelib,is_dir,[DirToClone]) of
			      {badrpc,Reason}->
				  {error,[badrpc,Reason,?MODULE,?FUNCTION_NAME,?LINE]};
			      false->
				  {error,[DirToClone,eexists,"couldnt git clone application:",
					  App," GitPath:",GitPath," DirToClone:",DirToClone," on Node:",Node,?MODULE,?LINE]};
			      true->
				  case appl:git_clone_to_dir(Node,GitPath,DirToClone) of
				      {error,Reason}->
					  {error,[Reason,?MODULE,?FUNCTION_NAME,?LINE]};
				      {ok,_}->
					  case appl:load(Node,App,Paths) of
					      {error,Reason}->
						  {error,[Reason,?MODULE,?FUNCTION_NAME,?LINE]};
					      ok->
						  case appl:start(Node,App) of
						      {error,Reason}->
							  {error,[Reason,?MODULE,?FUNCTION_NAME,?LINE]};
						      ok->
							  case rpc:call(Node,App,ping,[]) of
							      pong->
								  {ok,Node,Appl,DirToClone};
							      pang->
								  {error,[pang,"couldnt connect to Node",Node,?MODULE,?LINE]}
							  end
						  end
					  end
				  end
			  end
		  end;
	      ReasonRmGitCloneDirFailed->
		  {error,[ReasonRmGitCloneDirFailed,?MODULE,?FUNCTION_NAME,?LINE]}
	  end,
    Reply.

%% --------------------------------------------------------------------
%% Function:start/0 
%% Description: Initiate the eunit tests, set upp needed processes etc
%% Returns: non
%% --------------------------------------------------------------------


