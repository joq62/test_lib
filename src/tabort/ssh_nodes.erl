%%% -------------------------------------------------------------------
%%% Author  : uabjle
%%% Description : dbase using dets 
%%% 
%%% Created : 10 dec 2012
%%% -------------------------------------------------------------------
-module(ssh_nodes).     
    
%% --------------------------------------------------------------------
%% Include files
%% --------------------------------------------------------------------

%%---------------------------------------------------------------------
%% Records for test
%%

%% --------------------------------------------------------------------
%-compile(export_all).

-export([
	 install_oam_db/2,
	 install_first_node/2,
	 init/2,
	 init_tables/3
	 ]).


-define(StorageType,ram_copies).
-define(WAIT_FOR_TABLES,2*5000).

%% ====================================================================
%% External functions
%% ====================================================================
%% --------------------------------------------------------------------
%% Function:start/0 
%% Description: Initiate the eunit tests, set upp needed processes etc
%% Returns: non
%% --------------------------------------------------------------------
add_nodes(FirstNode,DbCallBacks)->

    ok.


%% --------------------------------------------------------------------
%% Function:start/0 
%% Description: Initiate the eunit tests, set upp needed processes etc
%% Returns: non
%% --------------------------------------------------------------------
install_first_node(FirstNode,DbCallBacks)->
    Nodes=[],
    ok=rpc:call(FirstNode,application,load,[db]),
    ok=rpc:call(FirstNode,application,set_env,
		[[{db,[{db_callbacks,DbCallBacks},
				 {nodes,Nodes}]}]]),
    ok=rpc:call(FirstNode,application,start,[db]),

    DynamicDbInitTables=dynamic_db:init_tables(DbCallBacks,node(),FirstNode),  
    DynamicDbInitTables.

%% --------------------------------------------------------------------
%% Function:start/0 
%% Description: Initiate the eunit tests, set upp needed processes etc
%% Returns: non
%% --------------------------------------------------------------------
install_oam_db(DbCallBacks,Nodes)->
    application:start(config),
%    rpc:cast(node(),nodelog,log,[notice,?MODULE_STRING,?LINE,
%				 {"DBG, DbCallBacks ",DbCallBacks,node()}]), 
%    rpc:cast(node(),nodelog,log,[notice,?MODULE_STRING,?LINE,
%				 {"DBG, Nodes ",Nodes,node()}]), 

   
    % Install local
    DynamicDbInit=dynamic_db:init(DbCallBacks,[]),
   % rpc:cast(node(),nodelog,log,[notice,?MODULE_STRING,?LINE,
%				 {"DBG, DynamicDbInit ",DynamicDbInit,node()}]),
    DynamicDbInitTables=dynamic_db:init_tables(DbCallBacks,node(),node()),
 %   rpc:cast(node(),nodelog,log,[notice,?MODULE_STRING,?LINE,
%				 {"DBG, DynamicDbInitTables ",DynamicDbInitTables,node()}]),   
    
    [FirstNode|NodesToAdd]=Nodes,
    {ok,FirstNode,NodesToAdd}.

%% --------------------------------------------------------------------
%% Function:start/0 
%% Description: Initiate the eunit tests, set upp needed processes etc
%% Returns: non
%% --------------------------------------------------------------------
init_tables(DbCallbacks,Source,Dest)->
    InitTables=[{CallBack,CallBack:init_table(Source,Dest)}||CallBack<-DbCallbacks],
    rpc:cast(node(),nodelog,log,[notice,?MODULE_STRING,?LINE,
				 {"DBG: CreateTables   ",?MODULE,node()}]),  
    InitTables.

%% --------------------------------------------------------------------
%% Function:start/0 
%% Description: Initiate the eunit tests, set upp needed processes etc
%% Returns: non
%% --------------------------------------------------------------------
init(DbCallbacks,Nodes)->
    mnesia:stop(),
    mnesia:delete_schema([node()]),
    mnesia:start(),
    start(DbCallbacks,Nodes).

%% --------------------------------------------------------------------
%% Function:start/0 
%% Description: Initiate the eunit tests, set upp needed processes etc
%% Returns: non
%% --------------------------------------------------------------------
start(DbCallbacks,[])->
    % Add unique code to create the specific tables
 %% Create tables on TestNode
    CreateTables=[{CallBack,CallBack:create_table()}||CallBack<-DbCallbacks],
    rpc:cast(node(),nodelog,log,[notice,?MODULE_STRING,?LINE,
				 {"DBG: CreateTables   ",?MODULE,node()}]), 
    CreateTables;

start(DbCallbacks,Nodes) ->
    rpc:cast(node(),nodelog,log,[notice,?MODULE_STRING,?LINE,
				 {"DBG: Nodes   ",Nodes,node()}]), 
    add_extra_nodes(DbCallbacks,Nodes).


%% --------------------------------------------------------------------
%% Function:start/0 
%% Description: Initiate the eunit tests, set upp needed processes etc
%% Returns: non
%% --------------------------------------------------------------------
add_extra_nodes(DbCallbacks,[Node|T])->
    case mnesia:change_config(extra_db_nodes,[Node]) of
	{ok,[Node]}->
	    rpc:cast(node(),nodelog,log,[notice,?MODULE_STRING,?LINE,
					 {"DBG: add_extra_nodes Node at node()  ",Node,?MODULE,node()}]), 
 
	    AddSchema=mnesia:add_table_copy(schema,node(),?StorageType),
	    rpc:cast(node(),nodelog,log,[notice,?MODULE_STRING,?LINE,
					 {"DBG: add_extra_nodes AddSchema  ",AddSchema,?MODULE,node()}]), 
	    TablesFromNode=rpc:call(Node,mnesia,system_info,[tables]),
	    rpc:cast(node(),nodelog,log,[notice,?MODULE_STRING,?LINE,
					 {"DBG: TablesFromNode  ",TablesFromNode}]), 
	    AddTableCopies=[{Table,mnesia:add_table_copy(Table,node(),?StorageType)}||Table<-TablesFromNode,
										      Table/=schema],
	    rpc:cast(node(),nodelog,log,[notice,?MODULE_STRING,?LINE,
				 {"DBG: AddTableCopies  ",AddTableCopies,?MODULE,node()}]), 
	    Tables=mnesia:system_info(tables),
	    rpc:cast(node(),nodelog,log,[notice,?MODULE_STRING,?LINE,
					 {"DBG: add_extra_nodes Tables  ",Tables,?MODULE,node()}]),
	    WaitForTables=mnesia:wait_for_tables(Tables,?WAIT_FOR_TABLES),
	    rpc:cast(node(),nodelog,log,[notice,?MODULE_STRING,?LINE,
					 {"DBG: add_extra_nodes WaitForTables  ",WaitForTables,?MODULE,node()}]);
	Reason->
	    rpc:cast(node(),nodelog,log,[notice,?MODULE_STRING,?LINE,
					 {"DBG: Didnt connect to Node Reason  ",Reason,?MODULE,node()}]),
	    add_extra_nodes(DbCallbacks,T)
    end.


