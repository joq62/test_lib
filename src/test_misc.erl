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
	 create_basic_appls/3
	 
	 ]).
-define(BasicAppls,["common","sd","nodelog"]).
%% ====================================================================
%% External functions
%% ====================================================================

create_basic_appls(HostName,NodeName,NodeDir)->
    Ip=config:host_local_ip(HostName),
    Port=config:host_ssh_port(HostName),
    Uid=config:host_uid(HostName),
    Passwd=config:host_passwd(HostName),
    TimeOut=7000,

    Reply=case ssh_vm:create_dir(HostName,NodeName,NodeDir,
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


git_load_start(Node,Appl,NodeDir)->
    DirToClone=filename:join(NodeDir,Appl),
    io:format("DirToClone ~p~n",[{DirToClone,?MODULE,?FUNCTION_NAME,?LINE}]),
    GitPath=config:application_gitpath(Appl++".spec"),
    App=list_to_atom(Appl),
    Paths=[filename:join([NodeDir,Appl,"ebin"])],    

    Reply=case rpc:call(Node,os,cmd,["rm -rf "++DirToClone]) of
	      []->
		  case rpc:call(Node,file,make_dir,[DirToClone]) of
		      ok->
			  case rpc:call(Node,filelib,is_dir,[DirToClone]) of
			      true->
				  case appl:git_clone_to_dir(Node,GitPath,DirToClone) of
				      {ok,_}->
					  case appl:load(Node,App,Paths) of
					      ok->
						  case appl:start(Node,App) of
						      ok->
							  case rpc:call(Node,App,ping,[]) of
							      pong->
								  {ok,Node,Appl,DirToClone};
							      pang->
								  {error,[pang,"couldnt connect to Node",Node,?MODULE,?LINE]}
							  end;
						      Reason->
							  {error,[Reason,"couldnt start application:",App," on Node:",Node,?MODULE,?LINE]}
						  end;
					      Reason->
						  {error,[Reason,"couldnt load application:",App," on Node:",Node,?MODULE,?LINE]}
					  end;
				      Reason->
					  {error,[Reason,"couldnt git clone application:",App," GitPath:",GitPath," DirToClone:",DirToClone," on Node:",Node,?MODULE,?LINE]}
				  end;
			      false->
				  {error,[DirToClone,eexists,"couldnt git clone application:",App," GitPath:",GitPath," DirToClone:",DirToClone," on Node:",Node,?MODULE,?LINE]}
			  end;
		      Reason->
			  {error,[Reason,"couldnt make DirToClone when git clone application:",App," GitPath:",GitPath," DirToClone:",DirToClone," on Node:",Node,?MODULE,?LINE]}
		  end;
	      Reason->
		  {error,[Reason,"couldnt rm DirToClone when git clone application:",App," GitPath:",GitPath," DirToClone:",DirToClone," on Node:",Node,?MODULE,?LINE]}
	  end,
    Reply.

%% --------------------------------------------------------------------
%% Function:start/0 
%% Description: Initiate the eunit tests, set upp needed processes etc
%% Returns: non
%% --------------------------------------------------------------------


%% --------------------------------------------------------------------
%% Function:start/0 
%% Description: Initiate the eunit tests, set upp needed processes etc
%% Returns: non
%% --------------------------------------------------------------------

