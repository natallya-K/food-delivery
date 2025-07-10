-- Database Exploration Queries
-- Getting familiar with the data structure and content

-- 1. Count records in each table
SELECT 'restaurants' AS table_name, COUNT(*) AS record_count FROM restaurants
UNION ALL
SELECT 'locations', COUNT(*) FROM locations
UNION ALL
SELECT 'menuItems', COUNT(*) FROM menuItems
UNION ALL
SELECT 'categories', COUNT(*) FROM categories
UNION ALL
SELECT 'categories_restaurants', COUNT(*) FROM categories_restaurants
UNION ALL
SELECT 'locations_to_restaurants', COUNT(*) FROM locations_to_restaurants;

-- 2. Sample of restaurants with their categories
SELECT DISTINCT 
    r.name AS restaurant_name,
    r.ratings,
    r.ratingsNumber,
    r.city,
    cr.category_id
FROM restaurants r
LEFT JOIN categories_restaurants cr ON r.primarySlug = cr.restaurant_id
LIMIT 10;

-- 3. Sample menu items with prices
SELECT 
    mi.name AS item_name,
    mi.description,
    mi.price,
    mi.primarySlug AS restaurant_slug
FROM menuItems mi
WHERE mi.price IS NOT NULL
LIMIT 10;

-- 4. Restaurant locations overview
SELECT 
    r.city,
    COUNT(*) AS restaurant_count,
    AVG(r.ratings) AS avg_rating,
    MIN(r.ratings) AS min_rating,
    MAX(r.ratings) AS max_rating
FROM restaurants r
WHERE r.ratings IS NOT NULL
GROUP BY r.city
ORDER BY restaurant_count DESC
LIMIT 10;
