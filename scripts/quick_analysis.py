#!/usr/bin/env python3
"""
Quick SQL Query Runner for Food Delivery Analysis
Execute all must-have questions at once
"""

import sqlite3
import pandas as pd

def run_queries():
    # Connect to database
    conn = sqlite3.connect('database/takeaway.db')
    
    print("🍕 FOOD DELIVERY MARKET ANALYSIS - QUICK RESULTS")
    print("=" * 60)
    
    # 1. Price Distribution
    print("\n1️⃣ PRICE DISTRIBUTION OF MENU ITEMS")
    price_stats = pd.read_sql_query("""
    SELECT 
        COUNT(*) AS total_items,
        ROUND(MIN(price), 2) AS min_price,
        ROUND(MAX(price), 2) AS max_price,
        ROUND(AVG(price), 2) AS avg_price
    FROM menuItems WHERE price IS NOT NULL AND price > 0
    """, conn)
    print(price_stats.to_string(index=False))
    
    # 2. Restaurant Distribution
    print("\n2️⃣ TOP 10 CITIES BY RESTAURANT COUNT")
    city_dist = pd.read_sql_query("""
    SELECT city, COUNT(*) AS restaurant_count
    FROM restaurants WHERE city IS NOT NULL
    GROUP BY city ORDER BY restaurant_count DESC LIMIT 10
    """, conn)
    print(city_dist.to_string(index=False))
    
    # 3. Top Pizza Restaurants
    print("\n3️⃣ TOP 5 PIZZA RESTAURANTS")
    top_pizza = pd.read_sql_query("""
    SELECT r.name, r.city, r.ratings, r.ratingsNumber
    FROM restaurants r
    JOIN categories_restaurants cr ON r.primarySlug = cr.restaurant_id
    WHERE cr.category_id LIKE '%pizza%' AND r.ratings IS NOT NULL
    ORDER BY r.ratings DESC, r.ratingsNumber DESC LIMIT 5
    """, conn)
    print(top_pizza.to_string(index=False))
    
    # 4. Kapsalon Analysis
    print("\n4️⃣ KAPSALON AVAILABILITY")
    kapsalon = pd.read_sql_query("""
    SELECT COUNT(*) AS kapsalon_items, 
           ROUND(AVG(mi.price), 2) AS avg_price,
           COUNT(DISTINCT r.city) AS cities_available
    FROM menuItems mi
    JOIN restaurants r ON mi.primarySlug = r.primarySlug
    WHERE LOWER(mi.name) LIKE '%kapsalon%' AND mi.price IS NOT NULL
    """, conn)
    print(kapsalon.to_string(index=False))
    
    # 5. Best Value Restaurants
    print("\n5️⃣ BEST VALUE RESTAURANTS (Top 5)")
    best_value = pd.read_sql_query("""
    WITH restaurant_avg_prices AS (
        SELECT mi.primarySlug, AVG(mi.price) AS avg_menu_price
        FROM menuItems mi WHERE mi.price IS NOT NULL GROUP BY mi.primarySlug
    )
    SELECT r.name, r.city, r.ratings, 
           ROUND(rap.avg_menu_price, 2) AS avg_price,
           ROUND(r.ratings / rap.avg_menu_price, 3) AS value_ratio
    FROM restaurants r
    JOIN restaurant_avg_prices rap ON r.primarySlug = rap.primarySlug
    WHERE r.ratings IS NOT NULL AND r.ratingsNumber >= 10
    ORDER BY value_ratio DESC LIMIT 5
    """, conn)
    print(best_value.to_string(index=False))
    
    # 6. Dead Zones
    print("\n6️⃣ DELIVERY DEAD ZONES (Cities with <5 restaurants)")
    dead_zones = pd.read_sql_query("""
    SELECT city, COUNT(*) AS restaurant_count
    FROM restaurants WHERE city IS NOT NULL
    GROUP BY city HAVING restaurant_count < 5
    ORDER BY restaurant_count ASC LIMIT 10
    """, conn)
    print(f"Found {len(dead_zones)} cities with minimal coverage")
    if len(dead_zones) > 0:
        print(dead_zones.to_string(index=False))
    
    # 7. Vegetarian Options
    print("\n7️⃣ VEGETARIAN/VEGAN OPTIONS SUMMARY")
    veg_summary = pd.read_sql_query("""
    SELECT 
        COUNT(CASE WHEN LOWER(mi.name) LIKE '%vegan%' THEN 1 END) AS vegan_items,
        COUNT(CASE WHEN LOWER(mi.name) LIKE '%vegetarian%' OR LOWER(mi.name) LIKE '%veggie%' THEN 1 END) AS vegetarian_items,
        COUNT(*) AS total_items
    FROM menuItems mi
    """, conn)
    print(veg_summary.to_string(index=False))
    
    # 8. WHO (World Hummus Order)
    print("\n8️⃣ WORLD HUMMUS ORDER (WHO) - TOP 3")
    who = pd.read_sql_query("""
    SELECT r.name, r.city, r.ratings, COUNT(*) AS hummus_items
    FROM menuItems mi
    JOIN restaurants r ON mi.primarySlug = r.primarySlug
    WHERE LOWER(mi.name) LIKE '%hummus%'
    GROUP BY r.primarySlug, r.name, r.city, r.ratings
    ORDER BY r.ratings DESC, hummus_items DESC LIMIT 3
    """, conn)
    print(who.to_string(index=False))
    
    conn.close()
    print(f"\n✅ Quick analysis complete!")

if __name__ == "__main__":
    run_queries()
