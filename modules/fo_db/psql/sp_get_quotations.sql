DELIMITER $$

DROP PROCEDURE IF EXISTS sp_get_quotations $$
CREATE PROCEDURE sp_get_quotations()
BEGIN
  DECLARE done INT DEFAULT FALSE;
  DECLARE _message LONGTEXT;
  DECLARE json_result LONGTEXT DEFAULT '<itn_bo_messages>';

  DECLARE cur CURSOR FOR
    SELECT CONCAT('<itn_bo_message><id>',id,'</id><message><![CDATA[', message,']]></message></itn_bo_message>') FROM itn_bo_message WHERE etat = 0 AND created_at >= '2025-07-10';

  DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;

  OPEN cur;

  read_loop: LOOP
    FETCH cur INTO _message;
    IF done THEN
      LEAVE read_loop;
    END IF;

    SET json_result = CONCAT(
      json_result,
      _message
    );
  END LOOP;

  CLOSE cur;

  SET json_result = CONCAT(json_result, '</itn_bo_messages>');

  SELECT json_result AS result;
END$$

DELIMITER ;
