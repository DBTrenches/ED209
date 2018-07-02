
create or alter view ED209.all_query_usage
as
  select R1.session_id, R1.request_id, 
	(R1.request_objects_alloc_page_count-R1.request_objects_dealloc_page_count)*8/1024 as MB_CurrentAllocation,
      R1.request_objects_alloc_page_count*8/1024 as MB_allocated,
	  R1.request_objects_dealloc_page_count*8/1024 as MB_deallocated,
      isnull(x.text,y.text) as  Sqltext,
	  r4.login_name,
	  r4.host_name,
	  isnull(r2.start_time, r4.login_time) as start_time,
	  R2.total_elapsed_time/60000 total_elapsed_time_in_mins
  FROM ED209.all_request_usage R1
  left JOIN sys.dm_exec_requests R2 ON R1.session_id = R2.session_id and R1.request_id = R2.request_id
  left JOIN sys.dm_exec_connections  R3 ON R1.session_id = R3.session_id 
  left join sys.dm_exec_sessions r4 on r4.session_id = R1.session_id
  outer apply sys.dm_exec_sql_text(R2.plan_handle)x
  outer apply sys.dm_exec_sql_text(R3.most_recent_sql_handle)y




GO


