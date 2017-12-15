CREATE 
    ALGORITHM = UNDEFINED 
    SQL SECURITY DEFINER
VIEW `vw_generator_256` AS
    SELECT 
        ((`hi`.`n` << 4) | `lo`.`n`) AS `n`
    FROM
        (`vw_generator_16` `lo`
        JOIN `vw_generator_16` `hi`)
