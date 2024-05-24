
DROP TRIGGER IF EXISTS tr_recipe_difficulty;
DROP TRIGGER IF EXISTS tr_recipe_ingredient_not_null;
DROP TRIGGER IF EXISTS tr_cook_age_and_experience;
DROP TRIGGER IF EXISTS tr_cook_role;
DROP TRIGGER IF EXISTS tr_episode;
DROP TRIGGER IF EXISTS tr_tip_up_to_3;
DROP TRIGGER IF EXISTS tr_recipe_ingredient_one_main;
DROP TRIGGER IF EXISTS tr_episode_selection;
DROP TRIGGER IF EXISTS tr_recipe_cook_learns_cuisine;
DROP TRIGGER IF EXISTS tr_episode_judge_sel;
DROP TRIGGER IF EXISTS tr_judge_rates_cook;
DROP TRIGGER IF EXISTS tr_cal_portion_calculate;

DROP PROCEDURE IF EXISTS insert_episode_selection;
DROP PROCEDURE IF EXISTS insert_episode_judge;
DROP PROCEDURE IF EXISTS insert_judge_rates_cook;

DROP PROCEDURE IF EXISTS winner;

DROP PROCEDURE IF EXISTS insert_one_episode;
DROP PROCEDURE IF EXISTS insert_one_year;


DELIMITER //

CREATE TRIGGER tr_recipe_difficulty BEFORE INSERT ON recipe FOR EACH ROW
BEGIN
    IF new.difficulty NOT IN (1,2,3,4,5) THEN
        SIGNAL SQLSTATE '45000'
        SET message_text = "Cannot insert recipe because difficutly isn't between 1 and 5";
    END IF;
END//

CREATE TRIGGER tr_cal_portion_calculate AFTER INSERT ON recipe_ingredient FOR EACH ROW
BEGIN
    DECLARE add_calories INT;
    DECLARE old_cal_portion INT;

    SELECT cal_portion INTO old_cal_portion
    FROM recipe
    WHERE recipe_id = new.recipe_id;

    IF new.recipe_ingredient_description = 'gr' THEN
        SELECT (r.quantity/100)*i.cal_gr INTO add_calories
        FROM recipe_ingredient r
        INNER JOIN ingredient i ON i.ingredient_id = r.ingredient_id
        WHERE i.ingredient_id = new.ingredient_id AND r.recipe_id = new.recipe_id;
    ELSEIF new.recipe_ingredient_description = 'ml' THEN
        SELECT (r.quantity/100)*i.cal_ml INTO add_calories
        FROM recipe_ingredient r
        INNER JOIN ingredient i ON i.ingredient_id = r.ingredient_id
        WHERE i.ingredient_id = new.ingredient_id AND r.recipe_id = new.recipe_id;
    ELSE
        SET add_calories = 0;
    END IF;

    UPDATE recipe
    SET cal_portion = (old_cal_portion*portions + add_calories)/ portions
    WHERE recipe_id = new.recipe_id;
END//


CREATE TRIGGER tr_recipe_ingredient_not_null BEFORE INSERT ON recipe_ingredient FOR EACH ROW
BEGIN
    IF (new.quantity IS NULL AND new.recipe_ingredient_description IS NULL) THEN
        SIGNAL SQLSTATE '45000'
        SET message_text = "At least one of the two fields, quantity and recipe_ingredient_description, needs to not be null";
    END IF;
END//

CREATE TRIGGER tr_recipe_ingredient_one_main BEFORE INSERT ON recipe_ingredient FOR EACH ROW
BEGIN
    IF (new.main = 1) AND ((SELECT count(*) FROM recipe_ingredient WHERE main =1 AND recipe_id=new.recipe_id) <> 0) THEN
        SIGNAL SQLSTATE '45000'
        SET message_text = "Each recipe has only one main ingredient";
    END IF;
END//

CREATE TRIGGER tr_cook_age_and_experience BEFORE INSERT ON cook FOR EACH ROW
BEGIN 
    IF new.age IS NULL THEN
        SET new.age = (SELECT YEAR(now()) - YEAR(new.d_birth));
    END IF;
    IF new.exp_years >= (SELECT YEAR(now()) - YEAR(new.d_birth)) THEN
        SIGNAL SQLSTATE '45000'
        SET message_text = "A cook cannot have more years of experience than years of existance";
    END IF;
END//

CREATE TRIGGER tr_cook_role BEFORE INSERT ON cook_role FOR EACH ROW
BEGIN
    IF new.title NOT IN ("Chef", "Sous-chef", "A cook", "B cook", "C cook") THEN 
        SIGNAL SQLSTATE '45000'
        SET message_text = "Not valid cook role";
    END IF;
END//


CREATE TRIGGER tr_episode BEFORE INSERT ON episode FOR EACH ROW
BEGIN 
    IF (new.ep_num < 1 OR new.ep_num > 10) THEN
        SIGNAL SQLSTATE '45000'
        SET message_text = "Not valid episode number";
    END IF;
    IF (SELECT count(*) FROM episode WHERE year = new.year and ep_num = new.ep_num) >= 1 THEN
        SIGNAL SQLSTATE '45000'
        SET message_text = "This episode has already been added";
    END IF;
END//

CREATE TRIGGER tr_tip_up_to_3 BEFORE INSERT ON recipe_tip FOR EACH ROW
BEGIN
    IF (SELECT count(*) FROM recipe_tip WHERE recipe_id = new.recipe_id) >=3 THEN
        SIGNAL SQLSTATE '45000'
        SET message_text = "Cannot add more tips for this recipe";
    END IF;
END//





CREATE TRIGGER tr_episode_selection BEFORE INSERT ON episode_selection FOR EACH ROW
BEGIN
    DECLARE sel_count INT;
    DECLARE cook_count INT;
    DECLARE nat_count INT;
    DECLARE rec_count INT;
    DECLARE cook_recipe_count INT;
    DECLARE rec_nat INT;

    DECLARE consec INT;
    SET consec=0;


    SELECT cuisine_id INTO rec_nat FROM recipe WHERE recipe_id = new.recipe_id;
    SET new.cuisine_id = rec_nat;
    SELECT count(*) INTO sel_count FROM episode_selection WHERE episode_id = new.episode_id;
    IF sel_count >= 10 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Only 10 selections per episode';
    END IF;
    SELECT count(*) INTO cook_count FROM episode_selection WHERE episode_id = new.episode_id AND cook_id = new.cook_id;
    IF cook_count >=1 THEN
        SIGNAL SQLSTATE '45000'
        SET message_text = "This cook has already been selected for this episode";
    END IF;
    SELECT count(*) INTO nat_count FROM episode_selection WHERE episode_id = new.episode_id AND cuisine_id = new.cuisine_id;
    IF nat_count >=1 THEN
        SIGNAL SQLSTATE '45000'
        SET message_text = "This cuisine has already been selected for this episode";
    END IF;
    SELECT count(*) INTO rec_count FROM episode_selection WHERE episode_id = new.episode_id AND recipe_id = new.recipe_id;
    IF rec_count >=1 THEN
        SIGNAL SQLSTATE '45000'
        SET message_text = "This recipe has already been selected for this episode";
    END IF;
    SELECT count(*) INTO cook_recipe_count FROM recipe_cook WHERE recipe_id = new.recipe_id AND cook_id = new.cook_id;
    IF cook_recipe_count = 0 THEN   
        INSERT INTO recipe_cook VALUES (new.recipe_id, new.cook_id);
    END IF;




    SELECT count(*) INTO consec FROM episode_selection
    WHERE cook_id = new.cook_id AND (episode_id = new.episode_id +1 OR episode_id = new.episode_id +2 OR episode_id = new.episode_id +3);
    IF consec =3 THEN
        SIGNAL SQLSTATE '45000'
        SET message_text = "A cook cannot participate in 3 consecutive episodes";
    END IF;

    IF new.episode_id > 1 THEN
        SELECT count(*) INTO consec FROM episode_selection
        WHERE cook_id = new.cook_id AND (episode_id = new.episode_id -1 OR episode_id = new.episode_id +1 OR episode_id = new.episode_id +2);
        IF consec =3 THEN
            SIGNAL SQLSTATE '45000'
            SET message_text = "A cook cannot participate in 3 consecutive episodes";
        END IF;
    END IF;

    IF new.episode_id >2 THEN
        SELECT count(*) INTO consec FROM episode_selection
        WHERE cook_id = new.cook_id AND (episode_id = new.episode_id -2 OR episode_id = new.episode_id -1 OR episode_id = new.episode_id+1);
        IF consec =3 THEN
            SIGNAL SQLSTATE '45000'
            SET message_text = "A cook cannot participate in 3 consecutive episodes";
        END IF;
    END IF;

    IF new.episode_id >3 THEN
        SELECT count(*) INTO consec FROM episode_selection
        WHERE cook_id = new.cook_id AND (episode_id = new.episode_id -3 OR episode_id = new.episode_id -2 OR episode_id = new.episode_id-1);
        IF consec =3 THEN
            SIGNAL SQLSTATE '45000'
            SET message_text = "A cook cannot participate in 3 consecutive episodes";
        END IF;
    END IF;






    SELECT count(*) INTO consec FROM episode_selection
    WHERE cuisine_id = new.cuisine_id AND (episode_id = new.episode_id +1 OR episode_id = new.episode_id +2 OR episode_id = new.episode_id +3);
    IF consec =3 THEN
        SIGNAL SQLSTATE '45000'
        SET message_text = "A cuisine cannot participate in 3 consecutive episodes";
    END IF;

    IF new.episode_id > 1 THEN
        SELECT count(*) INTO consec FROM episode_selection
        WHERE cuisine_id = new.cuisine_id AND (episode_id = new.episode_id -1 OR episode_id = new.episode_id +1 OR episode_id = new.episode_id +2);
        IF consec =3 THEN
            SIGNAL SQLSTATE '45000'
            SET message_text = "A cuisine cannot participate in 3 consecutive episodes";
        END IF;
    END IF;

    IF new.episode_id >2 THEN
        SELECT count(*) INTO consec FROM episode_selection
        WHERE cuisine_id = new.cuisine_id AND (episode_id = new.episode_id -2 OR episode_id = new.episode_id -1 OR episode_id = new.episode_id+1);
        IF consec =3 THEN
            SIGNAL SQLSTATE '45000'
            SET message_text = "A cuisine cannot participate in 3 consecutive episodes";
        END IF;
    END IF;

    IF new.episode_id >3 THEN
        SELECT count(*) INTO consec FROM episode_selection
        WHERE cuisine_id = new.cuisine_id AND (episode_id = new.episode_id -3 OR episode_id = new.episode_id -2 OR episode_id = new.episode_id-1);
        IF consec =3 THEN
            SIGNAL SQLSTATE '45000'
            SET message_text = "A cuisine cannot participate in 3 consecutive episodes";
        END IF;
    END IF;






    SELECT count(*) INTO consec FROM episode_selection
    WHERE recipe_id = new.recipe_id AND (episode_id = new.episode_id +1 OR episode_id = new.episode_id +2 OR episode_id = new.episode_id +3);
    IF consec =3 THEN
        SIGNAL SQLSTATE '45000'
        SET message_text = "A recipe cannot participate in 3 consecutive episodes";
    END IF;

    IF new.episode_id > 1 THEN
        SELECT count(*) INTO consec FROM episode_selection
        WHERE recipe_id = new.recipe_id AND (episode_id = new.episode_id -1 OR episode_id = new.episode_id +1 OR episode_id = new.episode_id +2);
        IF consec =3 THEN
            SIGNAL SQLSTATE '45000'
            SET message_text = "A recipe cannot participate in 3 consecutive episodes";
        END IF;
    END IF;

    IF new.episode_id >2 THEN
        SELECT count(*) INTO consec FROM episode_selection
        WHERE recipe_id = new.recipe_id AND (episode_id = new.episode_id -2 OR episode_id = new.episode_id -1 OR episode_id = new.episode_id+1);
        IF consec =3 THEN
            SIGNAL SQLSTATE '45000'
            SET message_text = "A recipe cannot participate in 3 consecutive episodes";
        END IF;
    END IF;

    IF new.episode_id >3 THEN
        SELECT count(*) INTO consec FROM episode_selection
        WHERE recipe_id = new.recipe_id AND (episode_id = new.episode_id -3 OR episode_id = new.episode_id -2 OR episode_id = new.episode_id-1);
        IF consec =3 THEN
            SIGNAL SQLSTATE '45000'
            SET message_text = "A recipe cannot participate in 3 consecutive episodes";
        END IF;
    END IF;
END//


CREATE TRIGGER tr_recipe_cook_learns_cuisine AFTER INSERT ON recipe_cook FOR EACH ROW
BEGIN
    DECLARE nat_id INT;
    DECLARE already_exists INT;
    SELECT cuisine_id INTO nat_id FROM recipe WHERE recipe_id = new.recipe_id;
    SELECT count(*) INTO already_exists FROM cook_cuisine WHERE cook_id = new.cook_id AND cuisine_id = nat_id;
    IF already_exists = 0 THEN 
        INSERT INTO cook_cuisine VALUES (new.cook_id, nat_id);
    END IF;
END//


CREATE TRIGGER tr_episode_judge_sel BEFORE INSERT ON episode_judge FOR EACH ROW
BEGIN 
    DECLARE judge_count INT;
    DECLARE judge_as_competitor INT;
    DECLARE consec INT;
    SET consec =0;

    SELECT count(*) INTO judge_count FROM episode_judge WHERE episode_id = new.episode_id;
    IF judge_count >=3 THEN 
        SIGNAL SQLSTATE '45000'
        SET message_text = "Only 3 judges per episode please";
    END IF;
    SELECT count(*) INTO judge_as_competitor FROM episode_selection WHERE episode_id = new.episode_id AND cook_id = new.cook_id;
    IF judge_as_competitor <> 0 THEN
        SIGNAL SQLSTATE '45000'
        SET message_text = "A cook cannot be a judge in an episode they compete in";
    END IF;


    SELECT count(*) INTO consec FROM episode_judge
    WHERE cook_id = new.cook_id AND (episode_id = new.episode_id +1 OR episode_id = new.episode_id +2 OR episode_id = new.episode_id +3);
    IF consec =3 THEN
        SIGNAL SQLSTATE '45000'
        SET message_text = "A judge cannot participate in 3 consecutive episodes";
    END IF;

    IF new.episode_id > 1 THEN
        SELECT count(*) INTO consec FROM episode_judge
        WHERE cook_id = new.cook_id AND (episode_id = new.episode_id -1 OR episode_id = new.episode_id +1 OR episode_id = new.episode_id+2);
        IF consec =3 THEN
            SIGNAL SQLSTATE '45000'
            SET message_text = "A judge cannot participate in 3 consecutive episodes";
        END IF;
    END IF;

    IF new.episode_id >2 THEN
        SELECT count(*) INTO consec FROM episode_judge
        WHERE cook_id = new.cook_id AND (episode_id = new.episode_id -2 OR episode_id = new.episode_id -1 OR episode_id = new.episode_id+1);
        IF consec =3 THEN
            SIGNAL SQLSTATE '45000'
            SET message_text = "A judge cannot participate in 3 consecutive episodes";
        END IF;
    END IF;

    IF new.episode_id >3 THEN
        SELECT count(*) INTO consec FROM episode_judge
        WHERE cook_id = new.cook_id AND (episode_id = new.episode_id -3 OR episode_id = new.episode_id -2 OR episode_id = new.episode_id-1);
        IF consec =3 THEN
            SIGNAL SQLSTATE '45000'
            SET message_text = "A judge cannot participate in 3 consecutive episodes";
        END IF;
    END IF;
END//

CREATE TRIGGER tr_judge_rates_cook BEFORE INSERT ON judge_rates_cook FOR EACH ROW
BEGIN
    DECLARE judge_in_episode INT;
    DECLARE cook_in_episode INT;

    IF (new.rating > 5 OR new.rating <1) THEN
        SIGNAL SQLSTATE '45000'
        SET message_text = "Rating has to be between 1 and 5";
    END IF;

    SELECT count(*) INTO judge_in_episode FROM episode_judge WHERE episode_id = new.episode_id AND cook_id = new.judge_id;
    SELECT count(*) INTO cook_in_episode FROM episode_selection WHERE episode_id = new.episode_id AND cook_id = new.cook_id;
    IF judge_in_episode = 0 THEN
        SIGNAL SQLSTATE '45000'
        SET message_text = "This cook isn't a judge in this episode";
    END IF;

    IF cook_in_episode = 0 THEN
        SIGNAL SQLSTATE '45000'
        SET message_text = "This cook isn't competitor in this episode";
    END IF;
END//


CREATE PROCEDURE insert_episode_selection()
BEGIN
    DECLARE i INT DEFAULT 1;
    DECLARE j INT DEFAULT 1;
    
    DECLARE CONTINUE HANDLER FOR SQLEXCEPTION BEGIN END;

    WHILE i <= (SELECT count(*) FROM episode) DO
        IF (SELECT count(*) FROM episode_selection WHERE episode_id = i) = 0 THEN 
            WHILE j <= 50 DO
                BEGIN
                    INSERT INTO episode_selection VALUES (i, FLOOR(RAND()*52+1), NULL, FLOOR(RAND()*55+1));
                END;
            SET j = j + 1;
            END WHILE;
        END IF;
        SET j = 1;
        SET i = i + 1;
    END WHILE;
END//


CREATE PROCEDURE insert_episode_judge()
BEGIN
    DECLARE i INT DEFAULT 1;
    DECLARE j INT DEFAULT 1;
    
    DECLARE CONTINUE HANDLER FOR SQLEXCEPTION BEGIN END;

    WHILE i <= (SELECT count(*) FROM episode) DO
        IF (SELECT count(*) FROM episode_judge WHERE episode_id = i) = 0 THEN
            WHILE j <= 10 DO
                BEGIN
                    INSERT INTO episode_judge VALUES (i, FLOOR(RAND()*52+1));
                END;
                SET j = j + 1;
            END WHILE;
        END IF;
        SET j = 1;
        SET i = i + 1;
    END WHILE;
END//

CREATE PROCEDURE insert_judge_rates_cook()
BEGIN
    DECLARE i INT DEFAULT 1;
    DECLARE j INT DEFAULT 1;
    DECLARE j1 INT;
    DECLARE j2 INT;
    DECLARE j3 INT;
    
    DECLARE CONTINUE HANDLER FOR SQLEXCEPTION BEGIN END;
 
    WHILE i <= (SELECT count(*) FROM episode) DO
        IF (SELECT count(*) FROM judge_rates_cook WHERE episode_id = i) = 0 THEN
            SELECT cook_id INTO j1 FROM episode_judge WHERE episode_id = i ORDER BY cook_id ASC LIMIT 1;
            SELECT cook_id INTO j2 FROM episode_judge WHERE episode_id = i ORDER BY cook_id ASC LIMIT 1 OFFSET 1;
            SELECT cook_id INTO j3 FROM episode_judge WHERE episode_id = i ORDER BY cook_id ASC LIMIT 1 OFFSET 2;

            WHILE j<=600 DO
                BEGIN
                    INSERT INTO judge_rates_cook VALUES (i, j1,FLOOR(RAND()*52+1), FLOOR(RAND()*5+1));
                    INSERT INTO judge_rates_cook VALUES (i, j2,FLOOR(RAND()*52+1), FLOOR(RAND()*5+1));
                    INSERT INTO judge_rates_cook VALUES (i, j3,FLOOR(RAND()*52+1), FLOOR(RAND()*5+1));
                END;
                SET j= j+1;
            END WHILE;
        END IF;
        SET i = i + 1;
        SET j =1;
    END WHILE;
END//


CREATE PROCEDURE winner(IN ep_id INT, OUT winner_id INT)
BEGIN
    SELECT j.cook_id INTO winner_id
    FROM judge_rates_cook j
    INNER JOIN cook c ON j.cook_id = c.cook_id
    WHERE j.episode_id = ep_id
    GROUP BY j.cook_id
    HAVING sum(rating) = (
        SELECT sum(rating) FROM judge_rates_cook WHERE episode_id = ep_id GROUP BY cook_id ORDER BY sum(rating) DESC LIMIT 1
    )
    ORDER BY c.cook_role_id LIMIT 1;
END//







CREATE PROCEDURE insert_one_episode(IN ep_id INT)
BEGIN
    DECLARE j INT DEFAULT 1;
    DECLARE j1 INT;
    DECLARE j2 INT;
    DECLARE j3 INT;
    DECLARE CONTINUE HANDLER FOR SQLEXCEPTION BEGIN END;
    
    IF (SELECT count(*) FROM episode_selection WHERE episode_id = ep_id) = 0 THEN
        WHILE j <= 100 DO
            BEGIN
                INSERT INTO episode_selection VALUES (ep_id, FLOOR(RAND()*52+1), NULL, FLOOR(RAND()*55+1));
            END;
            SET j = j + 1;
        END WHILE;
    END IF;

    SET j=1;    
    IF (SELECT count(*) FROM episode_judge WHERE episode_id = ep_id) = 0 THEN
        WHILE j <= 10 DO
            BEGIN
                INSERT INTO episode_judge VALUES (ep_id, FLOOR(RAND()*52+1));
            END;
            SET j = j + 1;
        END WHILE;
    END IF;




    SET j=1;    
    IF (SELECT count(*) FROM judge_rates_cook WHERE episode_id = ep_id) = 0 THEN
        SELECT cook_id INTO j1 FROM episode_judge WHERE episode_id = ep_id ORDER BY cook_id ASC LIMIT 1;
        SELECT cook_id INTO j2 FROM episode_judge WHERE episode_id = ep_id ORDER BY cook_id ASC LIMIT 1 OFFSET 1;
        SELECT cook_id INTO j3 FROM episode_judge WHERE episode_id = ep_id ORDER BY cook_id ASC LIMIT 1 OFFSET 2;

        WHILE j<=600 DO
            BEGIN
                INSERT INTO judge_rates_cook VALUES (ep_id, j1,FLOOR(RAND()*52+1), FLOOR(RAND()*5+1));
                INSERT INTO judge_rates_cook VALUES (ep_id, j2,FLOOR(RAND()*52+1), FLOOR(RAND()*5+1));
                INSERT INTO judge_rates_cook VALUES (ep_id, j3,FLOOR(RAND()*52+1), FLOOR(RAND()*5+1));
            END;
            SET j= j+1;
        END WHILE;
    END IF;
END//

CREATE PROCEDURE insert_one_year(IN y INT)
BEGIN
    DECLARE i INT DEFAULT 1;
    DECLARE j INT;

    SET j = 1 + (y - 2019)*10;

    WHILE (i<=10) DO
        CALL insert_one_episode(j);
        SET i=i+1;
        SET j=j+1;
    END WHILE;
END//

DELIMITER ;