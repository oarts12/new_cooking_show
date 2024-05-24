9.

SELECT 
    e.year,
    AVG(r.carbo_portion*r.portions) AS avg_carbo_grams
FROM 
    episode_selection es
JOIN 
    recipe r ON es.recipe_id = r.recipe_id
JOIN 
    episode e ON es.episode_id = e.episode_id
GROUP BY 
    e.year
ORDER BY 
    e.year;



15.
SELECT food_group_id,
    title AS food_group_name
FROM
    food_group
WHERE food_group_id NOT IN (
    SELECT DISTINCT fg.food_group_id
    FROM food_group fg
    JOIN ingredient i ON fg.food_group_id = i.food_group_id
    JOIN recipe_ingredient ri ON i.ingredient_id = ri.ingredient_id
    JOIN episode_selection es ON ri.recipe_id = es.recipe_id
);
