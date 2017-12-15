CREATE PROCEDURE `sp_delimited_to_table`(
  IN str LONGTEXT,
  IN del VARCHAR(4)
)
BEGIN
    /*
        USAGE 
        call sp_delimited_to_table('1,2,3,4,5,6,7,8,9', ',');
        select * from temp_delimited_string_to_table;
    */
    DROP TEMPORARY TABLE IF EXISTS temp_delimited_string_to_table;
    
    IF(str IS NULL OR str = '') THEN
    CREATE TEMPORARY TABLE temp_delimited_string_to_table
      SELECT NULL AS `position`, NULL AS `item`;
    ELSE
      CREATE TEMPORARY TABLE temp_delimited_string_to_table
      SELECT *
      FROM
      (
        SELECT 
           position
          ,TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(str, del, position + 1), del, -1)) AS `item`
        FROM
        (
          SELECT n AS `position` 
          FROM vw_generator_64k
        ) tallyGenerator
        WHERE position <= (CHAR_LENGTH(str) - CHAR_LENGTH(REPLACE(str, del, '')))
      ) delimitedString;
    END IF;
END
