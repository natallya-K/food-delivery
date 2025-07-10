-- MUST-HAVE QUESTIONS SQL QUERIES

-- 1. Price distribution of menu items
SELECT 
    'Price Distribution Analysis' AS analysis_type,
    COUNT(*) AS total_items,
    MIN(price) AS min_price,
    MAX(price) AS max_price,
    AVG(price) AS avg_price,
    PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY price) AS median_price,
    PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY price) AS q1_price,
    PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY price) AS q3_price
FROM menuItems 
WHERE price IS NOT NULL AND price > 0;

-- Price ranges for distribution
SELECT 
    CASE 
        WHEN price < 5 THEN '€0-5'
        WHEN price < 10 THEN '€5-10'
        WHEN price < 15 THEN '€10-15'
        WHEN price < 20 THEN '€15-20'
        WHEN price < 30 THEN '€20-30'
        ELSE '€30+'
    END AS price_range,
    COUNT(*) AS item_count,
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM menuItems WHERE price IS NOT NULL), 2) AS percentage
FROM menuItems 
WHERE price IS NOT NULL AND price > 0
GROUP BY 
    CASE 
        WHEN price < 5 THEN '€0-5'
        WHEN price < 10 THEN '€5-10'
        WHEN price < 15 THEN '€10-15'
        WHEN price < 20 THEN '€15-20'
        WHEN price < 30 THEN '€20-30'
        ELSE '€30+'
    END
ORDER BY MIN(price);

-- 2. Distribution of restaurants per location (city)
SELECT 
    city,
    COUNT(*) AS restaurant_count,
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM restaurants), 2) AS percentage
FROM restaurants 
WHERE city IS NOT NULL
GROUP BY city
ORDER BY restaurant_count DESC;

-- 3. Top 10 pizza restaurants by rating
SELECT 
    r.name AS restaurant_name,
    r.city,
    r.ratings,
    r.ratingsNumber AS total_reviews,
    r.deliveryFee,
    r.minOrder
FROM restaurants r
JOIN categories_restaurants cr ON r.primarySlug = cr.restaurant_id
WHERE cr.category_id LIKE '%pizza%' 
    AND r.ratings IS NOT NULL
ORDER BY r.ratings DESC, r.ratingsNumber DESC
LIMIT 10;

-- 4. Locations offering kapsalons and their average price
SELECT 
    r.city,
    r.name AS restaurant_name,
    mi.name AS item_name,
    mi.price,
    r.latitude,
    r.longitude
FROM menuItems mi
JOIN restaurants r ON mi.primarySlug = r.primarySlug
WHERE LOWER(mi.name) LIKE '%kapsalon%' 
    OR LOWER(mi.description) LIKE '%kapsalon%'
ORDER BY r.city, mi.price;

-- Average kapsalon price by city
SELECT 
    r.city,
    COUNT(*) AS kapsalon_count,
    AVG(mi.price) AS avg_price,
    MIN(mi.price) AS min_price,
    MAX(mi.price) AS max_price
FROM menuItems mi
JOIN restaurants r ON mi.primarySlug = r.primarySlug
WHERE (LOWER(mi.name) LIKE '%kapsalon%' 
    OR LOWER(mi.description) LIKE '%kapsalon%')
    AND mi.price IS NOT NULL
GROUP BY r.city
ORDER BY avg_price DESC;

-- 5. Restaurants with the best price-to-rating ratio
-- (Higher rating, lower average menu price = better ratio)
WITH restaurant_avg_prices AS (
    SELECT 
        mi.primarySlug,
        AVG(mi.price) AS avg_menu_price,
        COUNT(*) AS menu_items_count
    FROM menuItems mi
    WHERE mi.price IS NOT NULL AND mi.price > 0
    GROUP BY mi.primarySlug
)
SELECT 
    r.name AS restaurant_name,
    r.city,
    r.ratings,
    r.ratingsNumber,
    rap.avg_menu_price,
    rap.menu_items_count,
    ROUND(r.ratings / rap.avg_menu_price, 3) AS price_rating_ratio
FROM restaurants r
JOIN restaurant_avg_prices rap ON r.primarySlug = rap.primarySlug
WHERE r.ratings IS NOT NULL 
    AND r.ratingsNumber >= 10  -- Only restaurants with sufficient reviews
ORDER BY price_rating_ratio DESC
LIMIT 20;

-- 6. Delivery 'dead zones' - areas with minimal restaurant coverage
-- Cities with fewer restaurants relative to their postal code coverage
WITH city_coverage AS (
    SELECT 
        l.city,
        COUNT(DISTINCT l.postalCode) AS postal_codes,
        COUNT(DISTINCT r.primarySlug) AS restaurant_count,
        ROUND(COUNT(DISTINCT r.primarySlug) * 1.0 / COUNT(DISTINCT l.postalCode), 2) AS restaurants_per_postal_code
    FROM locations l
    LEFT JOIN locations_to_restaurants ltr ON l.ID = ltr.location_id
    LEFT JOIN restaurants r ON ltr.restaurant_id = r.primarySlug
    GROUP BY l.city
)
SELECT 
    city,
    postal_codes,
    restaurant_count,
    restaurants_per_postal_code
FROM city_coverage
WHERE restaurant_count < 5  -- Cities with very few restaurants
ORDER BY restaurants_per_postal_code ASC, postal_codes DESC;

-- 7. Vegetarian and vegan dish availability by area
SELECT 
    r.city,
    COUNT(CASE WHEN LOWER(mi.name) LIKE '%vegan%' 
               OR LOWER(mi.description) LIKE '%vegan%' THEN 1 END) AS vegan_items,
    COUNT(CASE WHEN LOWER(mi.name) LIKE '%vegetarian%' 
               OR LOWER(mi.description) LIKE '%vegetarian%'
               OR LOWER(mi.name) LIKE '%veggie%'
               OR LOWER(mi.description) LIKE '%veggie%' THEN 1 END) AS vegetarian_items,
    COUNT(*) AS total_items,
    ROUND(COUNT(CASE WHEN LOWER(mi.name) LIKE '%vegan%' 
                     OR LOWER(mi.description) LIKE '%vegan%' THEN 1 END) * 100.0 / COUNT(*), 2) AS vegan_percentage,
    ROUND(COUNT(CASE WHEN LOWER(mi.name) LIKE '%vegetarian%' 
                     OR LOWER(mi.description) LIKE '%vegetarian%'
                     OR LOWER(mi.name) LIKE '%veggie%'
                     OR LOWER(mi.description) LIKE '%veggie%' THEN 1 END) * 100.0 / COUNT(*), 2) AS vegetarian_percentage
FROM menuItems mi
JOIN restaurants r ON mi.primarySlug = r.primarySlug
WHERE r.city IS NOT NULL
GROUP BY r.city
HAVING total_items >= 10  -- Only cities with sufficient menu data
ORDER BY vegan_percentage DESC, vegetarian_percentage DESC;

-- 8. World Hummus Order (WHO) - Top 3 hummus serving restaurants
SELECT 
    r.name AS restaurant_name,
    r.city,
    r.ratings,
    r.ratingsNumber,
    COUNT(*) AS hummus_items,
    AVG(mi.price) AS avg_hummus_price,
    GROUP_CONCAT(mi.name, '; ') AS hummus_dishes
FROM menuItems mi
JOIN restaurants r ON mi.primarySlug = r.primarySlug
WHERE LOWER(mi.name) LIKE '%hummus%' 
    OR LOWER(mi.description) LIKE '%hummus%'
GROUP BY r.primarySlug, r.name, r.city, r.ratings, r.ratingsNumber
ORDER BY r.ratings DESC, hummus_items DESC, r.ratingsNumber DESC
LIMIT 3;
