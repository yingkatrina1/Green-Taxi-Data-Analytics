USE call_center_db;


-- q1
SELECT
	d.payment_type_description,
	COUNT(t.trip_id) AS total_trips,
	AVG(t.tip_amount) AS avg_tip,
	SUM(t.tip_amount) AS total_tips
FROM fact_trips t
JOIN dim_payment_type d ON t.payment_type_id = d.payment_type_id
GROUP BY d.payment_type_description;

-- q2
SELECT
    CASE
        WHEN t.trip_distance < 2 THEN 'Short (0-2 miles)'
        WHEN t.trip_distance BETWEEN 2 AND 5 THEN 'Medium (2-5 miles)'
        WHEN t.trip_distance BETWEEN 5 AND 10 THEN 'Long (5-10 miles)'
        ELSE 'Very Long'
    END AS distance_category,
    d.payment_type_description,
    AVG(t.tip_amount) AS avg_tip,
    COUNT(t.trip_id) AS total_trips
FROM fact_trips t
JOIN dim_payment_type d ON t.payment_type_id = d.payment_type_id
GROUP BY distance_category, d.payment_type_description
ORDER BY avg_tip DESC;

-- q3
WITH RankedTrips AS (
	SELECT
    	d.hour_of_day AS pickup_hour,
    	f.pulocationid,
    	COUNT(f.trip_id) AS total_trips,
    	RANK() OVER (PARTITION BY f.pulocationid ORDER BY COUNT(f.trip_id) DESC) AS rank_num
	FROM fact_trips f
	JOIN dim_date d ON f.lpep_pickup_date_id = d.date_id
	GROUP BY d.hour_of_day, f.pulocationid
	HAVING COUNT(f.trip_id) > 50
)
SELECT pickup_hour, pulocationid, total_trips
FROM RankedTrips
WHERE rank_num <= 3
ORDER BY pulocationid, rank_num;

-- q4
WITH PU_TripCounts AS (
    SELECT 
        pulocationid, 
        COUNT(trip_id) AS total_trips
    FROM fact_trips
    GROUP BY pulocationid
),
AverageTrips AS (
    SELECT AVG(total_trips) AS avg_trips FROM PU_TripCounts
)
SELECT 
    f.pulocationid, 
    SUM(total_amount) AS total_revenue,
    AVG(f.tip_amount * 100.0 / f.total_amount) AS avg_tip_percentage
FROM fact_trips f
JOIN PU_TripCounts pu ON f.pulocationid = pu.pulocationid
JOIN AverageTrips a ON pu.total_trips > a.avg_trips
GROUP BY f.pulocationid
ORDER BY avg_tip_percentage DESC;

-- q5
SELECT
    d.day_of_week,
    AVG(CASE WHEN d.is_peak_hour = 1 THEN f.extra END) AS avg_peak_extra,
    AVG(CASE WHEN d.is_peak_hour = 0 THEN f.extra END) AS avg_non_peak_extra
FROM fact_trips f
JOIN dim_date d 
    ON f.lpep_pickup_date_id = d.date_id
GROUP BY
    d.day_of_week;
