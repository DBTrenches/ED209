create or alter VIEW ED209.all_request_usage
AS 
  SELECT session_id, MAX(x.request_id) AS request_id ,
      SUM(internal_objects_alloc_page_count + user_objects_alloc_page_count) AS request_objects_alloc_page_count,
      SUM(internal_objects_dealloc_page_count + user_objects_dealloc_page_count)AS request_objects_dealloc_page_count 
  FROM (
            select  session_id
                   ,request_id
                   ,internal_objects_alloc_page_count
                   ,user_objects_alloc_page_count
                   ,internal_objects_dealloc_page_count
                   ,user_objects_dealloc_page_count
            from    sys.dm_db_task_space_usage
            union
            select  session_id
                   ,null
                   ,internal_objects_alloc_page_count
                   ,user_objects_alloc_page_count
                   ,internal_objects_dealloc_page_count
                   ,user_objects_dealloc_page_count
            from    sys.dm_db_session_space_usage
		) x
  GROUP BY session_id



GO


