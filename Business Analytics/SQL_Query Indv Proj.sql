With UnexpectedSales As (
    SELECT
        md.MerchandiseType As [Merchandise Type],
        dd.DateYear As [Year],
        Sum(osf.MerchandiseSoldPND) - Sum(osf.MerchandiseStockedPND) As [Unexpected Sales],
        ld.Country As [Country]
    From OnlineSalesFact osf
    Inner Join MerchandiseDim md On md.MerchandiseID = osf.MerchandiseID
    Inner Join DateDim dd On dd.DateID = osf.DateID
    Inner Join ProviderDim pd On md.MerchandiseProviderID = pd.ProviderID
    Inner Join LocationDim ld On ld.LocationID = pd.ProviderLocation
    Group By 
        md.MerchandiseType,
        dd.DateYear,
        ld.Country
)
Select TOP 5 
    [Merchandise Type],
    [Year],
    [Unexpected Sales]
FROM UnexpectedSales
WHERE [Country] = 'Japan'
ORDER BY [Unexpected Sales] DESC

----------------------------------------------------------------------------------------------------------------------------------------------------------

 With UnexpectedSales as (
    SELECT
        md.MerchandiseType As [Merchandise Type],
        dd.DateYear As [Year],
        Sum(osf.MerchandiseSold) As [Merchandise Sold],
        Sum(osf.MerchandiseStocked) As [Merchandise Stocked],
        Sum(osf.MerchandiseSold) - Sum(osf.MerchandiseStocked) As [Sale Difference],
        ld.Country As [Country]
    From OnlineSalesFact osf
    Inner Join MerchandiseDim md On md.MerchandiseID = osf.MerchandiseID
    Inner Join DateDim dd On dd.DateID = osf.DateID
    Inner Join ProviderDim pd On md.MerchandiseProviderID = pd.ProviderID
    Inner Join LocationDim ld On ld.LocationID = pd.ProviderLocation
    Group By 
        md.MerchandiseType,
        dd.DateYear,
        ld.Country
    )

    SELECT TOP 5
    [Merchandise Type],
    [Year],
    [Merchandise Sold],
    [Merchandise Stocked],
    [Sale Difference]
    FROM UnexpectedSales
    WHERE [Country] = 'Japan'
    Order By [Sale Difference] DESC;


------------------------------------------------------------------------------------------------------------------------------------------------------------
-- latest one

 With UnexpectedSales as (
    SELECT
        md.MerchandiseType As [Merchandise Type],
        dd.DateYear As [Year],
        Sum(osf.MerchandiseSold) As [Merchandise Sold],
        Sum(osf.MerchandiseStocked) As [Merchandise Stocked],
        (Round((Cast(Sum(osf.MerchandiseSold) As float) / Sum(osf.MerchandiseStocked) * 100), 2)) As [Percentage],
        ld.Country As [Country]
    From OnlineSalesFact osf
    Inner Join MerchandiseDim md On md.MerchandiseID = osf.MerchandiseID
    Inner Join DateDim dd On dd.DateID = osf.DateID
    Inner Join ProviderDim pd On md.MerchandiseProviderID = pd.ProviderID
    Inner Join LocationDim ld On ld.LocationID = pd.ProviderLocation
    Group By 
        md.MerchandiseType,
        dd.DateYear,
        ld.Country
    )

    SELECT TOP 5
    [Merchandise Type],
    [Year],
    [Merchandise Sold],
    [Merchandise Stocked],
    Concat([Percentage], ' %') As [Percentage]
    FROM UnexpectedSales
    WHERE [Country] = 'Japan'
    Order By [Percentage] DESC;


-- answer? 

WITH UnexpectedSales AS (
    SELECT
        md.MerchandiseType AS [Merchandise Type],
        dd.DateYear AS [Year],
        SUM(osf.MerchandiseSold) AS [Merchandise Sold],
        SUM(osf.MerchandiseStocked) AS [Merchandise Stocked],
        SUM(osf.MerchandiseSold) - SUM(osf.MerchandiseStocked) AS [Sale Difference],
        ld.Country AS [Country]
    FROM OnlineSalesFact osf
    INNER JOIN MerchandiseDim md ON md.MerchandiseID = osf.MerchandiseID
    INNER JOIN DateDim dd ON dd.DateID = osf.DateID
    INNER JOIN ProviderDim pd ON md.MerchandiseProviderID = pd.ProviderID
    INNER JOIN LocationDim ld ON ld.LocationID = pd.ProviderLocation
    GROUP BY 
        md.MerchandiseType,
        dd.DateYear,
        ld.Country
)

SELECT * FROM (
    SELECT TOP 1
        [Merchandise Type],
        [Year],
        [Country],
        [Sale Difference]
    FROM UnexpectedSales
    WHERE [Country] = 'Japan'
    ORDER BY [Sale Difference] DESC
) AS TopJapan

UNION

SELECT * FROM (
    SELECT TOP 1
        [Merchandise Type],
        [Year],
        [Country],
        [Sale Difference]
    FROM UnexpectedSales
    ORDER BY [Sale Difference] ASC
) AS BottomGlobal;

-- final answer

WITH UnexpectedSales AS (
    SELECT
        md.MerchandiseType AS [Merchandise Type],
        dd.DateYear AS [Year],
        SUM(osf.MerchandiseSold) AS [Merchandise Sold],
        SUM(osf.MerchandiseStocked) AS [Merchandise Stocked],
        Abs(SUM(osf.MerchandiseSold) - SUM(osf.MerchandiseStocked)) AS [Sale Difference],
        Concat((Round((Cast(Sum(osf.MerchandiseSold) As float) / Sum(osf.MerchandiseStocked) * 100), 2)), '%') As [Percentage Sold],
        ld.Country AS [Country]
    FROM OnlineSalesFact osf
    INNER JOIN MerchandiseDim md ON md.MerchandiseID = osf.MerchandiseID
    INNER JOIN DateDim dd ON dd.DateID = osf.DateID
    INNER JOIN ProviderDim pd ON md.MerchandiseProviderID = pd.ProviderID
    INNER JOIN LocationDim ld ON ld.LocationID = pd.ProviderLocation
    GROUP BY 
        md.MerchandiseType,
        dd.DateYear,
        ld.Country
)

SELECT * FROM (
    SELECT TOP 1
        [Merchandise Type],
        [Year],
        [Country],
        [Merchandise Stocked],
        [Merchandise Sold],
        [Sale Difference],
        [Percentage Sold]
    FROM UnexpectedSales
    WHERE [Country] = 'Japan'
    ORDER BY [Sale Difference] DESC
) AS MostUnexpectedSale

UNION

SELECT * FROM (
    SELECT TOP 1
        [Merchandise Type],
        [Year],
        [Country],
        [Merchandise Stocked],
        [Merchandise Sold],
        [Sale Difference],
        [Percentage Sold]
    FROM UnexpectedSales
    ORDER BY [Sale Difference] ASC
) AS LeastUnexpectedSale;



WITH UnexpectedSales AS (
    SELECT
        md.MerchandiseType AS [Merchandise Type],
        dd.DateYear AS [Year],
        Concat((Round((Cast(Sum(osf.MerchandiseSoldPND) As float) / Sum(osf.MerchandiseStockedPND) * 100), 2)), '%') As [Percentage Sold],
        Concat('£', Sum(osf.MerchandiseSoldPND)/Sum(osf.MerchandiseSold)) As [Sale Price Per Unit],
        Concat('£', Sum(osf.MerchandiseStockedPND)/Sum(osf.MerchandiseStocked)) As [Cost Price Per Unit],
        ld.Country AS [Country]
    FROM OnlineSalesFact osf
    INNER JOIN MerchandiseDim md ON md.MerchandiseID = osf.MerchandiseID
    INNER JOIN DateDim dd ON dd.DateID = osf.DateID
    INNER JOIN ProviderDim pd ON md.MerchandiseProviderID = pd.ProviderID
    INNER JOIN LocationDim ld ON ld.LocationID = pd.ProviderLocation
    GROUP BY 
        md.MerchandiseType,
        dd.DateYear,
        ld.Country
)

SELECT * FROM (
    SELECT TOP 1
        [Merchandise Type],
        [Year],
        [Country],
        [Percentage Sold],
        [Sale Price Per Unit],
        [Cost Price Per Unit]
    FROM UnexpectedSales
    WHERE [Country] = 'Japan'
    ORDER BY [Percentage Sold] ASC
) AS MostUnexpectedSale

UNION

SELECT * FROM (
    SELECT TOP 1
        [Merchandise Type],
        [Year],
        [Country],
        [Percentage Sold],
        [Sale Price Per Unit],
        [Cost Price Per Unit])
    FROM UnexpectedSales
    ORDER BY [Percentage Sold] DESC
) AS LeastUnexpectedSale

ORDER BY [Percentage Sold] ASC;


-- Avg(Sum(osf.MerchandiseSold) OVER (PARTITION BY osf.MerchandiseID)) AS [Average],
-- Abs(Sum(osf.MerchandiseSold) - Avg(Sum(osf.MerchandiseSold) OVER (PARTITION BY osf.MerchandiseID))) As [Unexpected Sales],
-- Sum(osf.MerchandiseSold) - Sum(osf.MerchandiseStocked) As [Amount Sold]
-- Avg(osf.MerchandiseStockedPND) As [Avg Stocked Amount],
-- Sum(osf.MerchandiseSoldPND) As [Total Amount Sold],


WITH UnexpectedSales AS (
    SELECT
        md.MerchandiseType AS [Merchandise Type],
        dd.DateYear AS [Year],
        SUM(osf.MerchandiseSold) AS [Merchandise Sold],
        SUM(osf.MerchandiseStocked) AS [Merchandise Stocked],
        Abs(SUM(osf.MerchandiseSold) - SUM(osf.MerchandiseStocked)) AS [Sale Difference],
        Concat((Round((Cast(Sum(osf.MerchandiseSold) As float) / Sum(osf.MerchandiseStocked) * 100), 2)), '%') As [Percentage Sold],
        ld.Country AS [Country]
    FROM OnlineSalesFact osf
    INNER JOIN MerchandiseDim md ON md.MerchandiseID = osf.MerchandiseID
    INNER JOIN DateDim dd ON dd.DateID = osf.DateID
    INNER JOIN ProviderDim pd ON md.MerchandiseProviderID = pd.ProviderID
    INNER JOIN LocationDim ld ON ld.LocationID = pd.ProviderLocation
    GROUP BY 
        md.MerchandiseType,
        dd.DateYear,
        ld.Country
)

    SELECT TOP 5
        [Merchandise Type],
        [Year],
        [Country],
        [Merchandise Stocked],
        [Merchandise Sold],
        [Sale Difference],
        [Percentage Sold]
    FROM UnexpectedSales
    WHERE [Country] = 'Japan'
    ORDER BY [Sale Difference] DESC
