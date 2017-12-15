CREATE VIEW `vw_generator_64k` AS
    SELECT 
        ((`hi`.`n` << 8) | `lo`.`n`) AS `n`
    FROM
        (`vw_generator_256` `lo`
        JOIN `vw_generator_256` `hi`)
