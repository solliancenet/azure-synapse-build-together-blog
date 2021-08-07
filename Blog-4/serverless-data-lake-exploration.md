# Episode 4: Serverless Data Lake Exploration and Streaming Analytics

## Table of Contents

## Introduction

In this blog post, you will learn how to utilize the Serverless SQL Pool in Azure Synapse Analytics to analyze a multitude of data sources, including real-time data from Cosmos DB. This allows you to build SQL-based BI platforms, while still being able to connect to real-time operational data. Lastly, you will understand how to work with streaming data in Synapse Analytics, including ingesting it into Synapse Analytics.

## Task 1: Introduction to Serverless SQL Pools

Serverless SQL Pools allow data engineers to query their data without managing compute clusters or the elasticity of those clusters (scaling in response to the workload). While this model is extremely flexible, customers desire controlling the costs of their Azure resources. This Task demonstrates how users of Serverless SQL pools can set usage limits.

1. Navigate to the **Manage** hub. Select **SQL pools** below **Analytics pools**.

2. Next to the **Built-in** serverless SQL pool, select the cost management button.

    ![Cost management button for the Built-in Serverless SQL Pool.](./media/cost-control.png "Cost management for the Built-in Serverless pool")

3. In the **Cost Control** window, observe how users can set daily limits, weekly limits, and monthly limits. Moreover, users can observe their current usage to adjust their limits or usage patterns. Read more about this cost control mechanism, including T-SQL support, in the [Azure documentation.](https://docs.microsoft.com/azure/synapse-analytics/sql/data-processed)

    ![Cost control for the Azure Synapse Analytics Built-in pool.](./media/built-in-pool-cost-control.png "Serverless pool cost control window")

## Task 2: Working with Azure Open Datasets and Serverless SQL Pools

In this Task, we will use a SQL script from the Knowledge center to query an Azure Open Dataset with the Built-in Serverless SQL pool. We will touch on the SQL facilities provided by the Synapse environment.

1. Navigate to the **Knowledge center** in your Synapse Workspace. Select **Browse gallery**.

2. Select the **SQL scripts** tab and the **Analyze Azure Open Datasets using serverless SQL pool** sample. Then, select **Continue**.

    ![Knowledge Center serverless SQL pool sample.](./media/kc-sample.png "Knowledge center sample")

3. Note the T-SQL code sample available on the right-hand side of the screen. Then, select **Open script**.

4. Once the script loads, note that you cannot run any queries until you attach a pool to it. Select the **Connect to** dropdown and choose the **Built-in** Serverless pool from the result.

5. Highlight the first query (lines 25-29) (1). Take note of the wildcards in the Blob Storage URI (i.e. `nyctlc/yellow/puYear=*/puMonth=*/*.parquet`). This indicates to select all Parquet files for all months for all years in the dataset. Execute the selection (2) and observe the result set (3).

    ![Executing the first cell of the SQL script and observing the output.](./media/executing-first-cell.png "First cell output")

6. Scroll to the query from lines 60 to 70. This query also makes use of wildcards to consolidate multiple Parquet files. However, note the use of the `filepath()` keyword. This keyword supports *partitioning* by limiting data within a particular range. In data warehouses, fact tables are usually partitioned. In this example, the query considers all years from 2009 to 2019, inclusive. The year is delineated by the first wildcard in the dataset hierarchy.

    ![Examining the use of the filepath() keyword in a query.](./media/filepath-keyword.png "filepath() hierarchy partitioning keyword")

7. The Synapse Workspace also makes it very easy to visualize result sets. In the output, select **Chart** (1). Then, change the **Chart type** to **Column** (2) to produce a visualization that summarizes the data well.

    ![Producing visualizations in Azure Synapse Analytics Workspace.](./media/chart-formatting-pbi.png "Visualization from query result set")

8. To learn more about the `filepath()` keyword, test the query below. It adds `nyc.filepath()` and `nyc.filepath(1)` to the SELECT and GROUP BY clauses. It also limits the year range. Correlate the Parquet file locations with the wildcards in the `OPENROWSET()` call (e.g. `nyc.filepath(1)` correlates to the year, `nyc.filepath(2)` correlates to the month, etc.)

    ```sql
    SELECT
        nyc.filepath(),
        nyc.filepath(1),
        YEAR(tpepPickupDateTime) AS current_year,
        COUNT(*) AS rides_per_year
    FROM
        OPENROWSET(
            BULK 'https://azureopendatastorage.blob.core.windows.net/nyctlc/yellow/puYear=*/puMonth=*/*.parquet',
            FORMAT='PARQUET'
        ) AS [nyc]
    WHERE nyc.filepath(1) >= '2009' AND nyc.filepath(1) <= '2010'
    GROUP BY nyc.filepath(), nyc.filepath(1), YEAR(tpepPickupDateTime)
    ORDER BY 1 ASC;
    ```

Feel free to explore the remainder of the samples in the Knowledge center example with your new knowledge of Serverless pools. However, notice that all queries utilize the flexibility of the `OPENROWSET()` function.

## Task: Provision Cosmos DB (SQL API)

To integrate Cosmos DB with your Synapse Workspace through Synapse Link, you need a source Cosmos DB account with a database. Follow this Task for more information.

1. In the Azure portal, select **+ Create a resource**. Select **Azure Cosmos DB**. On the **Select API option** page, select **Core (SQL) - Recommended**.

2. On the **Basics** tab, provide the following information. Then, select **Review + create**.

    - **Subscription**: Choose the same subscription that you used to provision Azure Synapse Analytics
    - **Resource group**: Choose the same resource group that your Synapse Workspace is located in
    - **Account name**: Provide a unique, descriptive name
    - **Location**: Choose the same location that you provisioned your Synapse Workspace in
    - **Capacity mode**: Choose **Provisioned throughput**
    - **Apply Free Tier Discount**: Apply the discount if it is available for your subscription

    ![Azure Cosmos DB provisioning Basics tab.](./media/cosmosdb-provision.png "Basics tab")

3. Once validation passes, select **Create**.
