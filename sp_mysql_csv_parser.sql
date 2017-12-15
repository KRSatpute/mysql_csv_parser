CREATE PROCEDURE `sp_mysql_csv_parser`(
	 csv longtext
    ,colDataType text
    ,seprtor varchar(4)
    ,lineBreak varchar(4)
)
begin
  set session group_concat_max_len = 100000000;

  set @csv = csv;

  set @data_type = colDataType;

  call sp_delimited_to_table(coalesce(@data_type,''), coalesce(seprtor,','));
  drop temporary table if exists `temp_sql_type`;
  create temporary table `temp_sql_type` as
  select 
     `position`
    ,item as `data_type`
    ,case item
      when 'int' then 'int'
      when 'string' then 'varchar(512)'
      when 'float' then 'decimal(20,4)'
      when 'date' then 'date'
      when 'datetime' then 'datetime'
      when 'bool' then 'bit'
      else 'varchar(512)'
     end as `sql_type`
  from temp_delimited_string_to_table;

  call sp_delimited_to_table(@csv, coalesce(lineBreak,'\n'));
  drop temporary table if exists `temp_rows`;
  create temporary table `temp_rows` as
  select * from temp_delimited_string_to_table;

  set @cols = (select item from temp_rows where `position` = 0);

  call sp_delimited_to_table(@cols, coalesce(seprtor,','));

  drop temporary table if exists `temp_csv`;
  set @sqlq =
  (
    select concat(
            'CREATE TEMPORARY TABLE IF NOT EXISTS temp_csv AS select * from ( '
            ,group_concat(cols separator ' union all ')
            ,' ) as dfl'
           )
    from
    (
      select 
        row_position
        ,concat('select ', group_concat(sql_col_item order by col_position separator ',')) as `cols`
      from
      (
        select 
           b.`position` as `col_position` 
          ,b.item as `col`
          ,b.data_type
          ,b.sql_type
          ,a.`position` as `row_position`
          ,a.item as `items`
          ,SPLIT_STR(a.item, ',', b.`position` + 1) as `col_item`
          ,case b.data_type
            when 'int' then concat('cast(', SPLIT_STR(a.item, ',', b.`position` + 1), ' as unsigned) as `',b.item,'`')
            when 'string' then concat('''', SPLIT_STR(a.item, ',', b.`position` + 1), ''' as `',b.item,'`')
            when 'float' then concat('cast(', SPLIT_STR(a.item, ',', b.`position` + 1), ' as decimal(20,4)) as `',b.item,'`')
            when 'date' then concat('cast(''', SPLIT_STR(a.item, ',', b.`position` + 1), ''' as date) as `',b.item,'`')
            when 'datetime' then concat('cast(''', SPLIT_STR(a.item, ',', b.`position` + 1), ''' as datetime) as `',b.item,'`')
            when 'bool' then 
                  case when a.item like '%true%' then concat('true as `',b.item,'`')
                  when a.item like '%false%' then concat('false as `',b.item,'`')
                  else concat('true as `',b.item,'`') end
            else concat('''', SPLIT_STR(a.item, ',', b.`position` + 1), ''' as `',b.item,'`')
           end as `sql_col_item`
        from 
        (
          select x.`position`, x.item, coalesce(y.sql_type, 'varchar(512)') as sql_type, coalesce(y.data_type, 'string') as data_type
          from temp_delimited_string_to_table x
           left outer join temp_sql_type y
            on x.`position` = y.`position`
        ) b 
        cross join temp_rows a
        where a.position <> 0
      ) as sci
      group by row_position
    ) as sc
  );

  PREPARE stmt FROM @sqlq; -- @sql;
  EXECUTE stmt;
  DEALLOCATE PREPARE stmt;

end
