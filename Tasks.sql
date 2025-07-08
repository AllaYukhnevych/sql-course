/*Кількість покупців, які придбали треки 5 і більше жанрів*/

SELECT 
 c.CustomerId
,c.FirstName 
, c.LastName 
, COUNT (DISTINCT g.GenreId ) AS nmb_genres
FROM InvoiceLine il 
LEFT JOIN Invoice i ON i.InvoiceId =il.InvoiceId
LEFT JOIN Customer c ON c.CustomerId =i.CustomerId
LEFT JOIN Track t ON t.TrackId =il.TrackId
LEFT JOIN Genre g ON g.GenreId = t.GenreId
GROUP BY 1,2,3
HAVING COUNT (DISTINCT g.GenreId )>=5

/* 28. Порівняти всіх музичних виконавчів за кількістю проданих музичних треків та загальною сумою продажу*/


SELECT 
  art.Name
, COUNT (DISTINCT t.TrackId ) AS nmb_track
, SUM (il.UnitPrice) AS sum_art
FROM InvoiceLine il 
LEFT JOIN Invoice i ON i.InvoiceId =il.InvoiceId
LEFT JOIN Track t ON t.TrackId =il.TrackId
LEFT JOIN Album a ON a.AlbumId =t.AlbumId
LEFT JOIN Artist art ON art.ArtistId =a.ArtistId
GROUP BY 1
ORDER BY 2 DESC

/* 29. Сформувати топ-3 співробітника за рівнем продажів для кожного року*/

SELECT 
e.EmployeeId
,e.FirstName
, e.LastName
, i.Total
, SUM (i.Total) AS sum_total
, strftime('%Y', i.InvoiceDate) AS year
FROM Invoice i
LEFT JOIN Customer c ON c.CustomerId =i.CustomerId
LEFT JOIN Employee e ON e.EmployeeId = c.SupportRepId
GROUP BY e.EmployeeId, year
ORDER BY   year DESC, sum_total DESC


/* 31. Надати інформацію про клієнтів, які придбали музичні треки в межах 4 різних жанрів*/

SELECT 
 c.CustomerId
,c.FirstName 
, c.LastName 
, COUNT (DISTINCT g.GenreId ) AS nmb_genres
FROM InvoiceLine il 
LEFT JOIN Invoice i ON i.InvoiceId =il.InvoiceId
LEFT JOIN Customer c ON c.CustomerId =i.CustomerId
LEFT JOIN Track t ON t.TrackId =il.TrackId
LEFT JOIN Genre g ON g.GenreId = t.GenreId
GROUP BY 1,2,3
HAVING COUNT (DISTINCT g.GenreId )>=4


/*32. Сформувати перелік клієнтів, які станом на останній місяць продажів не придбали нічого протягом 1 місяця, 2 місяців, 3 місяців
*/

WITH last_sale_date AS (
  SELECT MAX(InvoiceDate) AS max_date
  FROM Invoice
),
last_customer_purchase AS (
  SELECT 
    CustomerId,
    MAX(InvoiceDate) AS last_purchase_date
  FROM Invoice
  GROUP BY CustomerId
)
SELECT 
  c.CustomerId,
  c.FirstName,
  c.LastName,
  l.last_purchase_date
FROM last_customer_purchase l
JOIN Customer c ON c.CustomerId = l.CustomerId
JOIN last_sale_date d
WHERE JULIANDAY(d.max_date) - JULIANDAY(l.last_purchase_date) > 60
ORDER BY l.last_purchase_date;


/*33. Сформувати найбільш популярний жанр з числа перших покупок клієнтів*/

WITH inv_rank AS
(
SELECT 
il.InvoiceId
	, i.CustomerId 
	, i. InvoiceDate 
	, DENSE_RANK()		OVER(PARTITION BY i.CustomerId ORDER BY i.InvoiceDate ) AS invoice_rank
    , g.Name AS Name_gender
FROM InvoiceLine il 
LEFT JOIN Invoice i ON i.InvoiceId = il.InvoiceId
LEFT JOIN Track t ON t.TrackId =il.TrackId
LEFT JOIN Genre g ON g.GenreId =t.GenreId
ORDER By i.CustomerId
),
track_genres  AS
(
SELECT *
FROM inv_rank
WHERE invoice_rank=1
)


SELECT 
  Name_gender
 ,COUNT(*) AS genre_count
FROM track_genres
GROUP By Name_gender
ORDER BY genre_count DESC
LIMIT 1;

/*35. Вивести динаміку продажів музичних треків за останні 3 роки*/

SELECT 
 strftime('%Y', i.InvoiceDate) AS year
, COUNT (t.TrackId) AS nmb_track
 , ROUND(SUM(i.Total* il.Quantity ), 2) AS total_revenue
FROM InvoiceLine il 
LEFT JOIN Invoice i ON i.InvoiceId =il.InvoiceId
LEFT JOIN Track t ON t.TrackId =il.TrackId
GROUP BY year
ORDER BY year DESC
LIMIT 3;

/* 36. Дослідити кумулятивну суму продажів для кожного замовника*/

WITH cumul_total 
AS 
(
SELECT 
c.CustomerId 
,c.FirstName
, c.LastName
, i.Total
, SUM (i.Total) OVER (PARTITION BY c.CustomerId order by i.InvoiceDate  ) AS cumulative_total
FROM Invoice i
LEFT JOIN Customer c ON c.CustomerId =i.CustomerId
LEFT JOIN Employee e ON e.EmployeeId = c.SupportRepId
)

SELECT *
FROM cumul_total as ct

/*  37. Розрахувати середній чек*/

SELECT 
SUM (i.Total )/COUNT (DISTINCT i.invoiceID) AS average_check
FROM Invoice i 


/* 38. Розрахувати середню загальну суму продажу в перерахунку на одного замовника*/

SUM (i.Total )/COUNT (DISTINCT i.CustomerId ) AS average_check
FROM Invoice i 

/*40. Розрахувати середню тривалість періоду між першою покупкою і другою*/

WITH inv_rank AS 
(
SELECT 

	InvoiceId 
	, CustomerId 
	, InvoiceDate 
	, Total
	, JULIANDAY(InvoiceDate) - JULIANDAY(LAG(InvoiceDate, 1) OVER(Partition by CustomerId Order By InvoiceDate))  AS diff_in_days
	, ROW_NUMBER()		OVER(PARTITION BY CustomerId ORDER BY InvoiceDate ) AS invoice_rank
FROM Invoice i 
ORDER By CustomerId 
),

 avg_total AS (
SELECT 
InvoiceId 
	, CustomerId 
	, InvoiceDate 
	, Total
	, diff_in_days
	, invoice_rank
FROM inv_rank
WHERE invoice_rank=2
)

SELECT 
ROUND(AVG(diff_in_days),2)  AS avg_diff_in_days
FROM avg_total




