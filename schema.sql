DROP TABLE IF EXISTS recipe_meal_type; 
DROP TABLE IF EXISTS recipe_tag; 
DROP TABLE IF EXISTS recipe_equipment; 
DROP TABLE IF EXISTS recipe_tip;
DROP TABLE IF EXISTS recipe_ingredient;
DROP TABLE IF EXISTS recipe_cook; 
DROP TABLE IF EXISTS cook_cuisine; 
DROP TABLE IF EXISTS episode_selection;
DROP TABLE IF EXISTS episode_judge; 
DROP TABLE IF EXISTS judge_rates_cook;
DROP TABLE IF EXISTS cook; 
DROP TABLE IF EXISTS recipe_theme; 
DROP TABLE IF EXISTS step; 
DROP TABLE IF EXISTS recipe; 
DROP TABLE IF EXISTS cuisine; 
DROP TABLE IF EXISTS meal_type; 
DROP TABLE IF EXISTS tag; 
DROP TABLE IF EXISTS tip; 
DROP TABLE IF EXISTS equipment; 
DROP TABLE IF EXISTS ingredient; 
DROP TABLE IF EXISTS food_group; 
DROP TABLE IF EXISTS theme; 
DROP TABLE IF EXISTS cook_role; 
DROP TABLE IF EXISTS episode; 


CREATE TABLE cuisine(
    cuisine_id INT UNSIGNED NOT NULL AUTO_INCREMENT,
    title VARCHAR(255) NOT NULL,
    PRIMARY KEY (cuisine_id)
);

CREATE TABLE recipe(
    recipe_id INT UNSIGNED NOT NULL AUTO_INCREMENT,
    baking BOOLEAN NOT NULL,
    cuisine_id INT UNSIGNED NOT NULL,
    difficulty TINYINT NOT NULL,
    title VARCHAR(255) NOT NULL,
    recipe_description TEXT NOT NULL,
    prep_time INT NOT NULL,
    cook_time INT NOT NULL,
    portions SMALLINT NOT NULL,
    fat_portion SMALLINT NOT NULL,
    protein_portion SMALLINT NOT NULL,
    carbo_portion SMALLINT NOT NULL,
    cal_portion FLOAT NOT NULL DEFAULT 0,
    picture VARCHAR(255),
    picture_description TEXT,
    PRIMARY KEY(recipe_id),
    CONSTRAINT fk_recipecuisine FOREIGN KEY(cuisine_id) REFERENCES cuisine(cuisine_id)
);


CREATE TABLE meal_type(
    meal_type_id INT UNSIGNED NOT NULL AUTO_INCREMENT,
    title VARCHAR(255) NOT NULL,
    PRIMARY KEY (meal_type_id)
);

CREATE TABLE recipe_meal_type(
    recipe_id INT UNSIGNED NOT NULL,
    meal_type_id INT UNSIGNED NOT NULL,
    PRIMARY KEY (recipe_id, meal_type_id),
    CONSTRAINT fk_recipe_meal_type_recipe FOREIGN KEY(recipe_id) REFERENCES recipe(recipe_id) ON UPDATE CASCADE,
    CONSTRAINT fk_recipe_meal_type_meal_type FOREIGN KEY(meal_type_id) REFERENCES meal_type(meal_type_id) ON UPDATE CASCADE
);

CREATE TABLE tag(
    tag_id INT UNSIGNED NOT NULL AUTO_INCREMENT,
    title VARCHAR(255) NOT NULL,
    PRIMARY KEY (tag_id)
);

CREATE TABLE recipe_tag(
    recipe_id INT UNSIGNED NOT NULL,
    tag_id INT UNSIGNED NOT NULL,
    PRIMARY KEY (recipe_id, tag_id),    CONSTRAINT fk_recipe_tag_recipe FOREIGN KEY (recipe_id) REFERENCES recipe(recipe_id) ON UPDATE CASCADE,
    CONSTRAINT fk_recipe_tag_tag FOREIGN KEY (tag_id) REFERENCES tag(tag_id) ON UPDATE CASCADE
);

CREATE TABLE tip(
    tip_id INT UNSIGNED NOT NULL AUTO_INCREMENT,
    title VARCHAR(255) NOT NULL,
    PRIMARY KEY (tip_id)
);

CREATE TABLE recipe_tip(
    recipe_id INT UNSIGNED NOT NULL,
    tip_id INT UNSIGNED NOT NULL,
    PRIMARY KEY (recipe_id, tip_id),
    CONSTRAINT fk_recipe_tip_recipe FOREIGN KEY (recipe_id) REFERENCES recipe(recipe_id) ON UPDATE CASCADE,
    CONSTRAINT fk_recipe_tip_tip FOREIGN KEY (tip_id) REFERENCES tip (tip_id) ON UPDATE CASCADE
);


CREATE TABLE equipment(
    equipment_id INT UNSIGNED NOT NULL AUTO_INCREMENT,
    title VARCHAR(255) NOT NULL,
    details TEXT NOT NULL,
    picture VARCHAR(255),
    picture_description TEXT,
    PRIMARY KEY(equipment_id)
);

CREATE TABLE recipe_equipment(
    recipe_id INT UNSIGNED NOT NULL,
    equipment_id INT UNSIGNED NOT NULL,
    num SMALLINT NOT NULL,
    PRIMARY KEY (recipe_id, equipment_id),
    CONSTRAINT fk_recipe_equipment_recipe FOREIGN KEY (recipe_id) REFERENCES recipe(recipe_id) ON UPDATE CASCADE,
    CONSTRAINT fk_recipe_equipment_equipment FOREIGN KEY (equipment_id) REFERENCES equipment(equipment_id) ON UPDATE CASCADE
);

CREATE TABLE step(
    step_id INT UNSIGNED NOT NULL AUTO_INCREMENT,
    recipe_id INT UNSIGNED NOT NULL,
    step_order SMALLINT NOT NULL,
    details TEXT NOT NULL,
    PRIMARY KEY (step_id),
    CONSTRAINT fk_step_recipe FOREIGN KEY (recipe_id) REFERENCES recipe (recipe_id) ON UPDATE CASCADE
);

CREATE TABLE food_group(
    food_group_id INT UNSIGNED NOT NULL AUTO_INCREMENT,
    title VARCHAR(255) NOT NULL,
    char_if_main TEXT NOT NULL,
    picture VARCHAR(255),
    picture_description TEXT,
    PRIMARY KEY(food_group_id)
);


CREATE TABLE ingredient(
    ingredient_id INT UNSIGNED NOT NULL AUTO_INCREMENT,
    title VARCHAR(255) NOT NULL,
    cal_gr INT NOT NULL,
    cal_ml INT NOT NULL,
    food_group_id INT UNSIGNED NOT NULL,
    picture VARCHAR(255),
    picture_description TEXT,
    PRIMARY KEY (ingredient_id),
    CONSTRAINT fk_ingredient_food_group FOREIGN KEY (food_group_id) REFERENCES food_group (food_group_id) ON UPDATE CASCADE
);

CREATE TABLE recipe_ingredient(
    recipe_id INT UNSIGNED NOT NULL,
    ingredient_id INT UNSIGNED NOT NULL,
    quantity INT,
    recipe_ingredient_description VARCHAR(255),
    main BOOLEAN NOT NULL,
    PRIMARY KEY (recipe_id, ingredient_id),
    CONSTRAINT fk_recipe_ingredient_recipe FOREIGN KEY (recipe_id) REFERENCES recipe(recipe_id) ON UPDATE CASCADE,
    CONSTRAINT fk_recipe_ingredient_ingredient FOREIGN KEY (ingredient_id) REFERENCES ingredient (ingredient_id) ON UPDATE CASCADE
);



CREATE TABLE theme(
    theme_id INT UNSIGNED NOT NULL AUTO_INCREMENT,
    title VARCHAR(255) NOT NULL,
    theme_description TEXT NOT NULL,
    picture VARCHAR(255),
    picture_description TEXT,
    PRIMARY KEY (theme_id)
);

CREATE TABLE recipe_theme(
    recipe_id INT UNSIGNED NOT NULL,
    theme_id INT UNSIGNED NOT NULL,
    PRIMARY KEY (recipe_id, theme_id),
    CONSTRAINT fk_recipe_theme_recipe FOREIGN KEY (recipe_id) REFERENCES recipe (recipe_id) ON UPDATE CASCADE,
    CONSTRAINT fk_recipe_theme_theme FOREIGN KEY (theme_id) REFERENCES theme (theme_id) ON UPDATE CASCADE
);

CREATE TABLE cook_role(
    cook_role_id INT UNSIGNED NOT NULL AUTO_INCREMENT,
    title VARCHAR(255),
    PRIMARY KEY (cook_role_id)
);


CREATE TABLE cook(
    cook_id INT UNSIGNED NOT NULL AUTO_INCREMENT,
    first_name VARCHAR(255) NOT NULL,
    last_name VARCHAR(255) NOT NULL,
    phone VARCHAR (10) NOT NULL,
    d_birth DATE NOT NULL,
    age SMALLINT NOT NULL,
    exp_years SMALLINT NOT NULL,
    cook_role_id INT UNSIGNED NOT NULL,
    picture VARCHAR(255),
    picture_description TEXT,
    PRIMARY KEY (cook_id),
    CONSTRAINT fk_cook_cook_role FOREIGN KEY (cook_role_id) REFERENCES cook_role (cook_role_id) ON UPDATE CASCADE
);

CREATE TABLE recipe_cook(
    recipe_id INT UNSIGNED NOT NULL,
    cook_id INT UNSIGNED NOT NULL,
    PRIMARY KEY (recipe_id, cook_id),
    CONSTRAINT fk_recipe_cook_recipe FOREIGN KEY (recipe_id) REFERENCES recipe (recipe_id) ON UPDATE CASCADE,
    CONSTRAINT fk_recipe_cook_cook FOREIGN KEY (cook_id) REFERENCES cook (cook_id) ON UPDATE CASCADE
);

CREATE TABLE cook_cuisine(
    cook_id INT UNSIGNED NOT NULL,
    cuisine_id INT UNSIGNED NOT NULL,
    PRIMARY KEY (cook_id, cuisine_id),
    CONSTRAINT fk_cook_cuisine_cook FOREIGN KEY (cook_id) REFERENCES cook (cook_id) ON UPDATE CASCADE,
    CONSTRAINT fk_cook_cuisine_cuisine FOREIGN KEY (cuisine_id) REFERENCES cuisine (cuisine_id) ON UPDATE CASCADE
);

CREATE TABLE episode (
    episode_id INT UNSIGNED NOT NULL AUTO_INCREMENT,
    year CHAR(4) NOT NULL,
    ep_num TINYINT NOT NULL,
    picture VARCHAR(255),
    picture_description TEXT,
    PRIMARY KEY (episode_id)
);

CREATE TABLE episode_selection(
    episode_id INT UNSIGNED NOT NULL,
    cook_id INT UNSIGNED NOT NULL,
    cuisine_id INT UNSIGNED,
    recipe_id INT UNSIGNED NOT NULL,
    PRIMARY KEY (episode_id, cook_id, cuisine_id, recipe_id),
    CONSTRAINT fk_episode_selection_episode FOREIGN KEY (episode_id) REFERENCES episode (episode_id) ON UPDATE CASCADE,
    CONSTRAINT fk_episode_selection_cook FOREIGN KEY (cook_id) REFERENCES cook (cook_id) ON UPDATE CASCADE,
    CONSTRAINT fk_episode_selection_cuisine FOREIGN KEY (cuisine_id) REFERENCES cuisine (cuisine_id) ON UPDATE CASCADE,
    CONSTRAINT fk_episode_selection_recipe FOREIGN KEY (recipe_id) REFERENCES recipe (recipe_id) ON UPDATE CASCADE
);

CREATE TABLE episode_judge(
    episode_id INT UNSIGNED NOT NULL,
    cook_id INT UNSIGNED NOT NULL,
    PRIMARY KEY (episode_id, cook_id),
    CONSTRAINT fk_episode_judge_episode FOREIGN KEY (episode_id) REFERENCES episode (episode_id) ON UPDATE CASCADE,
    CONSTRAINT fk_episode_judge_cook FOREIGN KEY (cook_id) REFERENCES cook (cook_id) ON UPDATE CASCADE
);

CREATE TABLE judge_rates_cook(
    episode_id INT UNSIGNED NOT NULL,
    judge_id INT UNSIGNED NOT NULL,
    cook_id INT UNSIGNED NOT NULL,
    rating TINYINT NOT NULL,
    PRIMARY KEY (episode_id, judge_id, cook_id),
    CONSTRAINT fk_judge_rates_cook_episode FOREIGN KEY (episode_id) REFERENCES episode (episode_id) ON UPDATE CASCADE,
    CONSTRAINT fk_judge_rates_cook_judge FOREIGN KEY (judge_id) REFERENCES cook (cook_id) ON UPDATE CASCADE,
    CONSTRAINT fk_judge_rates_cook_cook FOREIGN KEY (cook_id) REFERENCES cook (cook_id) ON UPDATE CASCADE
);
