Create database music_analysis;
Use music_analysis;

-- Q1. Who is the senior most employee based on job title?
SELECT employee_id, first_name, last_name, levels FROM employee
WHERE
    CAST(SUBSTRING(levels, 2) AS UNSIGNED) = (
        SELECT MAX(CAST(SUBSTRING(levels, 2) AS UNSIGNED))
        FROM employee
        WHERE levels IS NOT NULL
    );

-- Q2. Which countries have the most invoices?
SELECT c.country, COUNT(i.invoice_id) AS invoice_count FROM customer c
JOIN invoice i ON c.customer_id = i.customer_id
GROUP BY c.country
ORDER BY invoice_count DESC;

-- Q3. What are the top 3 values of total invoice?
SELECT total FROM invoice ORDER BY total DESC LIMIT 3;

-- Q4. Which city has the best (highest total of invoice sums)?
SELECT c.city, SUM(i.total) AS total_revenue FROM customer c
JOIN invoice i ON c.customer_id = i.customer_id
GROUP BY c.city ORDER BY total_revenue DESC LIMIT 1;

-- Q5. Who is the best customer? The customer who has spent the most money will be declared the best customer. 
SELECT c.customer_id, c.first_name, c.last_name, SUM(i.total) AS total_spent FROM customer c
JOIN invoice i ON c.customer_id = i.customer_id
GROUP BY c.customer_id, c.first_name, c.last_name
ORDER BY total_spent DESC LIMIT 1;

-- Q6. Write a query to return the email, first name, last name, & Genre of all Rock Music listeners. 
--     Return your list ordered alphabetically by email starting with A 
SELECT c.email, c.first_name, c.last_name, g.name AS genre_name FROM customer c
JOIN invoice i ON c.customer_id = i.customer_id
JOIN invoice_line il ON i.invoice_id = il.invoice_id
JOIN track t ON il.track_id = t.track_id
JOIN genre g ON t.genre_id = g.genre_id
WHERE g.name LIKE '%Rock%'
GROUP BY c.customer_id, c.email, c.first_name, c.last_name, g.name
ORDER BY c.email ASC;

-- Q7. Let's invite the artists who have written the most rock music in our dataset. 
--     Write a query that returns the Artist name and total track count of the top 10 rock bands.
SELECT ar.name AS artist_name, COUNT(t.track_id) AS track_count FROM artist ar
JOIN album a ON ar.artist_id = a.artist_id
JOIN track t ON a.album_id = t.album_id
JOIN genre g ON t.genre_id = g.genre_id
WHERE g.name LIKE '%Rock%'
GROUP BY ar.artist_id, ar.name
ORDER BY track_count DESC
LIMIT 10;

-- Q8. Return all the track names that have a song length longer than the average song length. 
-- Return the Name and Milliseconds for each track. Order by the song length with the longest songs listed first.
SELECT t.name, t.milliseconds FROM track t
WHERE t.milliseconds > (SELECT AVG(milliseconds) FROM track)
ORDER BY t.milliseconds DESC;

-- Q9. Find how much amount spent by each customer on artists. Write a query to return the customer name, artist name, and total spent.
SELECT c.first_name, c.last_name, ar.name AS artist_name, SUM(il.unit_price * il.quantity) AS total_spent
FROM customer c
JOIN invoice i ON c.customer_id = i.customer_id
JOIN invoice_line il ON i.invoice_id = il.invoice_id
JOIN track t ON il.track_id = t.track_id
JOIN album a ON t.album_id = a.album_id
JOIN artist ar ON a.artist_id = ar.artist_id
GROUP BY c.customer_id, c.first_name, c.last_name, ar.artist_id, ar.name
ORDER BY c.first_name, c.last_name, ar.name;

-- Q10. We want to find out the most popular music Genre for each country. 
--      We determine the most popular genre as the genre with the highest amount of purchases. 
--      Write a query that returns each country along with the top Genre. For countries where the maximum number of purchases is shared return all Genres.
 WITH country_genre_amount AS (
    SELECT c.country, g.genre_id, g.name AS genre_name, SUM(il.unit_price * il.quantity) AS total_amount FROM customer c
    JOIN invoice i ON c.customer_id = i.customer_id JOIN invoice_line il ON i.invoice_id = il.invoice_id
    JOIN track t ON il.track_id = t.track_id JOIN genre g ON t.genre_id = g.genre_id
    GROUP BY c.country, g.genre_id, g.name
),
max_amount_per_country AS (
    SELECT country, MAX(total_amount) AS max_amount FROM country_genre_amount GROUP BY country
)
SELECT cga.country, cga.genre_name, cga.total_amount FROM country_genre_amount cga
JOIN max_amount_per_country mag ON cga.country = mag.country AND cga.total_amount = mag.max_amount;


-- Q11. Write a query that determines the customer that has spent the most on music for each country. 
-- Write a query that returns the country along with the top customer and how much they spent. 
-- For countries where the top amount spent is shared, provide all customers who spent this amount.
WITH country_customer_spent AS (
    SELECT c.country, c.customer_id, c.first_name, c.last_name, SUM(il.unit_price * il.quantity) AS total_spent 
    FROM customer c
    JOIN invoice i ON c.customer_id = i.customer_id
    JOIN invoice_line il ON i.invoice_id = il.invoice_id
    GROUP BY c.country, c.customer_id, c.first_name, c.last_name
),
max_spent_per_country AS (
    SELECT country, MAX(total_spent) AS max_spent FROM country_customer_spent GROUP BY country
)
SELECT ccs.country, ccs.first_name, ccs.last_name, ccs.total_spent FROM country_customer_spent ccs
JOIN max_spent_per_country msp ON ccs.country = msp.country AND ccs.total_spent = msp.max_spent;

-- Q12. Who are the most popular artists?
-- By total amount spent (on tracks purchased)
SELECT ar.artist_id, ar.name AS artist_name, SUM(il.unit_price * il.quantity) AS total_spent FROM artist ar
JOIN album a ON ar.artist_id = a.artist_id JOIN track t ON a.album_id = t.album_id
JOIN invoice_line il ON t.track_id = il.track_id
GROUP BY ar.artist_id, ar.name ORDER BY total_spent DESC LIMIT 10;

-- By number of tracks purchased:
SELECT ar.artist_id, ar.name AS artist_name, COUNT(DISTINCT t.track_id) AS tracks_bought FROM artist ar 
JOIN album a ON ar.artist_id = a.artist_id JOIN track t ON a.album_id = t.album_id
JOIN invoice_line il ON t.track_id = il.track_id
GROUP BY ar.artist_id, ar.name ORDER BY tracks_bought DESC LIMIT 10;


-- Q13. Which is the most popular song?
SELECT t.track_id, t.name AS track_name, COUNT(*) AS purchase_count FROM track t
JOIN invoice_line il ON t.track_id = il.track_id
GROUP BY t.track_id, t.name ORDER BY purchase_count DESC LIMIT 1;

-- Q14. What are the average prices of different types of music?
SELECT m.name AS media_type, AVG(t.unit_price) AS average_price FROM media_type m
JOIN track t ON m.media_type_id = t.media_type_id
GROUP BY m.media_type_id, m.name;

-- Q15. What are the most popular countries for music purchases?
-- Countries with the highest total sales amount (sum of invoice totals)
SELECT c.country, SUM(i.total) AS total_revenue FROM customer c
JOIN invoice i ON c.customer_id = i.customer_id
GROUP BY c.country ORDER BY total_revenue DESC LIMIT 5;

-- Countries with the most number of invoices/purchases
SELECT c.country, COUNT(i.invoice_id) AS total_invoices FROM customer c
JOIN invoice i ON c.customer_id = i.customer_id
GROUP BY c.country ORDER BY total_invoices DESC LIMIT 5;