CREATE VIEW `vw_generator_1m` AS
    SELECT 
        ((`hi`.`n` << 16) | `lo`.`n`) AS `n`
    FROM
        (`vw_generator_64k` `lo`
        JOIN `vw_generator_16` `hi`)
