-- NICE-TO-HAVE FEATURES AND CUSTOM ANALYSES

-- 1. Query Optimization Examples
-- Optimized version of restaurant search with indexes in mind
SELECT 
    r.name,
    r.city,
    r.ratings,
    cr.category_id
FROM restaurants r
JOIN categories_restaurants cr ON r.primarySlug = cr.restaurant_id
WHERE r.ratings > 4.0
    AND r.city IN ('Antwerp', 'Brussels', 'Ghent')
ORDER BY r.ratings DESC;

-- 2. Database Schema Improvement Suggestions
-- Query to identify missing indexes and potential improvements
-- (This would be implemented as comments for suggestions)

-- 3. CUSTOM ANALYSIS 1: Peak Hours Analysis (Delivery Duration Insights)
-- Analyzing delivery time patterns and efficiency
SELECT 
    r.city,
    AVG(r.durationRangeMin) AS avg_min_delivery,
    AVG(r.durationRangeMax) AS avg_max_delivery,
    AVG((r.durationRangeMin + r.durationRangeMax) / 2.0) AS avg_delivery_time,
    COUNT(*) AS restaurant_count
FROM restaurants r
WHERE r.durationRangeMin IS NOT NULL 
    AND r.durationRangeMax IS NOT NULL
GROUP BY r.city
HAVING restaurant_count >= 5
ORDER BY avg_delivery_time ASC;

-- Most efficient restaurants (shortest delivery times with good ratings)
SELECT 
    r.name AS restaurant_name,
    r.city,
    r.ratings,
    r.ratingsNumber,
    (r.durationRangeMin + r.durationRangeMax) / 2.0 AS avg_delivery_time,
    r.deliveryFee,
    CASE 
        WHEN (r.durationRangeMin + r.durationRangeMax) / 2.0 <= 30 THEN 'Fast'
        WHEN (r.durationRangeMin + r.durationRangeMax) / 2.0 <= 45 THEN 'Medium'
        ELSE 'Slow'
    END AS delivery_speed_category
FROM restaurants r
WHERE r.durationRangeMin IS NOT NULL 
    AND r.durationRangeMax IS NOT NULL
    AND r.ratings >= 4.0
    AND r.ratingsNumber >= 20
ORDER BY avg_delivery_time ASC
LIMIT 15;

-- 4. CUSTOM ANALYSIS 2: Market Saturation Analysis
-- Analyzing competition density and market opportunities
WITH city_metrics AS (
    SELECT 
        r.city,
        COUNT(*) AS total_restaurants,
        COUNT(DISTINCT cr.category_id) AS unique_categories,
        AVG(r.ratings) AS avg_city_rating,
        AVG(r.deliveryFee) AS avg_delivery_fee,
        AVG(r.minOrder) AS avg_min_order
    FROM restaurants r
    LEFT JOIN categories_restaurants cr ON r.primarySlug = cr.restaurant_id
    WHERE r.city IS NOT NULL
    GROUP BY r.city
),
category_saturation AS (
    SELECT 
        r.city,
        cr.category_id,
        COUNT(*) AS restaurants_in_category,
        AVG(r.ratings) AS category_avg_rating
    FROM restaurants r
    JOIN categories_restaurants cr ON r.primarySlug = cr.restaurant_id
    WHERE r.city IS NOT NULL
    GROUP BY r.city, cr.category_id
)
SELECT 
    cm.city,
    cm.total_restaurants,
    cm.unique_categories,
    ROUND(cm.avg_city_rating, 2) AS avg_rating,
    ROUND(cm.avg_delivery_fee, 2) AS avg_delivery_fee,
    ROUND(cm.avg_min_order, 2) AS avg_min_order,
    ROUND(cm.total_restaurants * 1.0 / cm.unique_categories, 2) AS restaurants_per_category,
    CASE 
        WHEN cm.total_restaurants > 50 AND cm.unique_categories > 15 THEN 'High Saturation'
        WHEN cm.total_restaurants > 20 AND cm.unique_categories > 8 THEN 'Medium Saturation'
        ELSE 'Low Saturation'
    END AS market_saturation_level
FROM city_metrics cm
ORDER BY cm.total_restaurants DESC;

-- 5. Restaurant Category Overlap Analysis
-- Which restaurants serve multiple cuisine types
SELECT 
    r.name AS restaurant_name,
    r.city,
    r.ratings,
    COUNT(DISTINCT cr.category_id) AS cuisine_count,
    GROUP_CONCAT(DISTINCT cr.category_id, ', ') AS cuisines_offered
FROM restaurants r
JOIN categories_restaurants cr ON r.primarySlug = cr.restaurant_id
GROUP BY r.primarySlug, r.name, r.city, r.ratings
HAVING cuisine_count > 1
ORDER BY cuisine_count DESC, r.ratings DESC
LIMIT 20;

-- 6. Price Competition Analysis by Category
WITH category_prices AS (
    SELECT 
        cr.category_id,
        r.city,
        mi.price,
        r.name AS restaurant_name,
        r.ratings
    FROM menuItems mi
    JOIN restaurants r ON mi.primarySlug = r.primarySlug
    JOIN categories_restaurants cr ON r.primarySlug = cr.restaurant_id
    WHERE mi.price IS NOT NULL AND mi.price > 0
)
SELECT 
    category_id,
    city,
    COUNT(*) AS items_count,
    ROUND(AVG(price), 2) AS avg_price,
    ROUND(MIN(price), 2) AS min_price,
    ROUND(MAX(price), 2) AS max_price,
    COUNT(DISTINCT restaurant_name) AS restaurants_in_category
FROM category_prices
WHERE category_id IN ('italian-pizza_271', 'asian_42', 'burger_275', 'indian_44')
GROUP BY category_id, city
HAVING restaurants_in_category >= 3
ORDER BY category_id, avg_price DESC;
