# Episode 4: Serverless Data Lake Exploration and Streaming Analytics

## Table of Contents

- [Episode 4: Serverless Data Lake Exploration and Streaming Analytics](#episode-4-serverless-data-lake-exploration-and-streaming-analytics)
  - [Table of Contents](#table-of-contents)
  - [Introduction](#introduction)
  - [Task 1: Provision Cosmos DB (SQL API)](#task-1-provision-cosmos-db-sql-api)
  - [Task 2: Prepare the Sample in Azure Synapse Analytics](#task-2-prepare-the-sample-in-azure-synapse-analytics)
  - [Task 3: Query Cosmos DB using the Serverless SQL Pool](#task-3-query-cosmos-db-using-the-serverless-sql-pool)
  - [Task 4: Cost Control in Serverless SQL Pools](#task-4-cost-control-in-serverless-sql-pools)
  - [Task 5: Working with Azure Open Datasets and Serverless SQL Pools](#task-5-working-with-azure-open-datasets-and-serverless-sql-pools)
  - [Task 6: Querying CSV Files with Serverless SQL Pools](#task-6-querying-csv-files-with-serverless-sql-pools)
  - [Task 7: Querying JSON Files with Serverless SQL Pools](#task-7-querying-json-files-with-serverless-sql-pools)
  - [Task 8: Working with Streaming Data (TODO)](#task-8-working-with-streaming-data-todo)
  - [Conclusion](#conclusion)

## Introduction

In this blog post, you will learn how to utilize the Serverless SQL Pool in Azure Synapse Analytics to analyze a multitude of data sources, including real-time data from Cosmos DB. This allows you to build SQL-based BI platforms, while still being able to connect to real-time operational data. Lastly, you will understand how to work with streaming data in Synapse Analytics, including ingesting it into Synapse Analytics.

## Task 1: Provision Cosmos DB (SQL API)

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

4. Once the resource finishes provisioning, navigate to your Cosmos DB account and select **Data Explorer** (1). Then, select **Enable Azure Synapse Link** (2).

    ![Enabling Synapse Link for the Cosmos DB account.](./media/cosmos-db-enable-link.png "Enabling Synapse Link")

5. Select **Enable Synapse Link**. Wait until this procedure completes.

## Task 2: Prepare the Sample in Azure Synapse Analytics

1. Upload the [sample notebook](CosmosDB-Setup/1CosmoDBSynapseSparkBatchIngestion.ipynb) to your Workspace. This notebook, from Microsoft's samples, uses PySpark to populate three Cosmos DB collections. Use the `livedemo` Apache Spark pool to execute the cells.

    >**Note**: The three CSV files referenced in the notebook are located in the [Data directory.](CosmosDB-Setup/Data/) You can upload these files to ADLS Gen2 directly from the Synapse Data hub, as shown in the notebook.

    >**Note**: Skip step 2 shown in the notebook. You are already an administrator of the Synapse environment.

## Task 3: Query Cosmos DB using the Serverless SQL Pool

Serverless SQL Pools allow data engineers to query their data without managing compute clusters or the elasticity of those clusters (scaling in response to the workload).

In this Task, we will explore how to use T-SQL queries in the Serverless SQL pool to query Cosmos DB, a transactional store. Note that these queries involve the *analytical store*, which operates independently of the transactional store. This means that you can write complex analytical queries in Azure Synapse Analytics against the transactional store, without impacting the performance of the transactional workloads.

1. On the **Data** hub, select the **Linked** tab (1). Expand **Azure Cosmos DB** and the **RetailSalesDemoDB** (2) linked service. Notice how the three containers you created in the previous task are indicated with an annotation showing that the analytical store is enabled.

    ![Analytical Store-enabled Cosmos DB containers in the Synapse Workspace.](./media/analytical-store-containers.png "Analytical Store-enabled containers")

2. Navigate to the **Develop** hub. Select **+** and **SQL script**.

    ![Creating a new SQL script in the Develop hub.](./media/create-new-sql-script.png "New SQL script")

3. Paste the following SQL code into the script. Make sure to replace the `Account` and `Key` placeholders. This query just returns 100 rows from the data store. Use the **Run** button in the upper left-hand corner of the SQL editor to run the command.

    ```sql
    SELECT TOP 100 *
    FROM OPENROWSET('CosmosDB', 'Account=[YOUR ACCOUNT];Database=RetailSalesDemoDB;Key=[YOUR KEY]', RetailSales) 
    AS Sales
    ```

    To find `[YOUR KEY]`, navigate to your Cosmos DB account in the Azure portal. Below **Settings**, select **Keys** (1). Then, select **Read-only Keys** (2). Use the **Primary Read-Only Key** as `[YOUR KEY]`.

    ![Obtaining Cosmos DB read-only key for Serverless SQL query.](./media/finding-cosmosdb-key.png "Cosmos DB read-only key")

4. Note that standard T-SQL aggregates work as well. Use the following SQL statement to count the number of rows in the **RetailSales** Cosmos DB container.

    ```sql
    SELECT COUNT(*)
    FROM OPENROWSET('CosmosDB', 'Account=[YOUR ACCOUNT];Database=RetailSalesDemoDB;Key=[YOUR KEY]', RetailSales) 
    AS Sales
    ```

5. Here is a more complicated example of using Serverless SQL pool to query a Cosmos DB collection. The first subquery just returns the product types, the number of transactions by product, and the sum of sales quantity by product. The outer query uses the subquery to determine the percentage of total sales transactions and total sales quantity by category.  

    ```sql
    SELECT 
        productCode,
        SalesTransaction,
        CAST((SalesTransaction / SUM(CAST(SalesTransaction AS DECIMAL(15, 2))) OVER (ORDER BY (SELECT NULL))) * 100 AS DECIMAL(15, 2)) AS SalesTransactionPct,
        SalesQuantity,
        CAST((SalesQuantity / SUM(CAST(SalesQuantity AS DECIMAL(15, 2))) OVER (ORDER BY (SELECT NULL))) * 100 AS DECIMAL(15, 2)) AS SalesQuantityPct
    FROM (
        SELECT
            productCode,
            COUNT(*) AS SalesTransaction,
            SUM(CAST(Quantity as INT)) AS SalesQuantity
        FROM OPENROWSET('CosmosDB', 'Account=cosmossynapselinksai;Database=RetailSalesDemoDB;Key=IpsiOoIzoEfEFcPvP9K3zbPErVHYRWVFFB1RMgfJBeyfGgPfxxhjGEZWeLdT6KV3EWXoeUtVy7E08EGFSjWbRw==', RetailSales) 
        AS Sales
        GROUP BY productCode) AS SubQ
    ```

## Task 4: Cost Control in Serverless SQL Pools

While this model is extremely flexible, customers desire controlling the costs of their Azure resources. This Task demonstrates how users of Serverless SQL pools can set usage limits.

1. Navigate to the **Manage** hub. Select **SQL pools** below **Analytics pools**.

2. Next to the **Built-in** serverless SQL pool, select the cost management button.

    ![Cost management button for the Built-in Serverless SQL Pool.](./media/cost-control.png "Cost management for the Built-in Serverless pool")

3. In the **Cost Control** window, observe how users can set daily limits, weekly limits, and monthly limits. Moreover, users can observe their current usage to adjust their limits or usage patterns. Read more about this cost control mechanism, including T-SQL support, in the [Azure documentation.](https://docs.microsoft.com/azure/synapse-analytics/sql/data-processed)

    ![Cost control for the Azure Synapse Analytics Built-in pool.](./media/built-in-pool-cost-control.png "Serverless pool cost control window")

## Task 5: Working with Azure Open Datasets and Serverless SQL Pools

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

## Task 6: Querying CSV Files with Serverless SQL Pools

In the previous Task, you queried Parquet files with the Serverless SQL pool. However, as CSV is a common file format used to move data to analytical systems, you will explore how to query CSV files with Serverless SQL pools.

1. Returning to the **SQL scripts** Knowledge center samples, search for `Query CSV Files`. Select the sample that appears.

    ![Query CSV files Knowledge center example.](./media/query-csv-files-kc.png "Selecting Query CSV Files example")

2. Select **Continue**. Once the sample preview loads, select **Open script**.

3. After connecting to the **Built-in** pool, highlight and execute the first query (lines 4-9). Note how the `OPENROWSET()` function references the CSV format and the most performant CSV parser version (`2.0`). Critically, note that the second row in the file is used as the first row of data; the first row in the file represents the header.

    ![Introductory query for parsing CSV data with Synapse Serverless SQL pools.](./media/result-set-csv-query.png "CSV file querying introduction")

    Note that if we substituted `firstrow = 1` into the query, the header would be displayed in the result set.

    ![Header returned in the result set for CSV file query.](./media/csv-query-header-in-results.png "Header in result set")

4. To retrieve specific columns from a CSV file, use the `WITH` clause, as shown in the second query in the sample (lines 14-24). In addition to specifying the name and data type of the CSV column, you must also specify the column's position in the file. For example, the `date_rep` column is the first column in the CSV file, and the `geo_id` column is the eight column in the file. Using column references simplifies naming and casting columns in the CSV file.

    ![Identifying, casting, and renaming columns in the source CSV file.](./media/renaming-csv-columns.png "CSV column manipulation with Serverless SQL pools")

Feel free to explore the remaining queries in the sample. For example, the query from line 66-81 explores collation.

## Task 7: Querying JSON Files with Serverless SQL Pools

JSON files are another common format that data engineers work with. Just like Parquet and CSV files, Synapse Serverless pools support a variety of techniques to manipulate them.

1. In the Knowledge center samples, search for the **Query JSON Files** SQL script. Select **Continue**.

    ![Query JSON Files Knowledge center example.](./media/query-json-files-kc.png "Selecting Query JSON Files example")

2. Once the preview loads, select **Open script**.

3. Connect the SQL script to the **Built-in** SQL pool. Then, navigate to the query from lines 45-61. This query uses the `JSON_VALUE()` function to extract JSON object fields from the traversed files. Note that we added a `TOP 10` clause to the query and excluded the `WHERE` clause to improve query result times.

    ![Querying JSON fields with the Serverless SQL pool.](./media/json-output-fields.png "JSON field queries using T-SQL")

4. Scroll to the next query (located on lines 68-83). This example uses the `JSON_QUERY()` function, as the `authors` field of the JSON object is a collection. Again, we have added a `TOP 10` clause and excluded the `WHERE` clause from the selection.

    ![Querying JSON collections with the Serverless SQL pool.](./media/json-collection-query.png "JSON collection queries using T-SQL")

## Task 8: Working with Streaming Data (TODO)

So far, we have have explored interacting with operational data from Cosmos DB and a variety of file formats. We will conclude with a brief overview of working with streaming data.

1. Navigate to the **Manage** hub and select **SQL pools**. Select **+ New**.

2. In the **Create dedicated SQL pool** window, provide a name for the new pool, such as **Streaming_Pool**. Then, lower the **Performance level** to **DW100c** to minimize expenses. Select **Review + create** once you finish this to provision the pool.

    ![Provisioning a dedicated pool.](./media/create-dedicated-pool.png "New dedicated pool")

3. Follow the instructions in [this](https://docs.microsoft.com/azure/stream-analytics/stream-analytics-real-time-fraud-detection) document from the Microsoft documentation. Stop once you arrive at the **Configure job output** section, as you will not be directing data to Power BI.

4. In your Stream Analytics job, select **Storage account settings** below **Configure**. Then, select **Add storage account**.

5. In the form that appears, select the ADLS Gen2 account that you are using from your subscription. Keep all other settings at their defaults. Once you are done, select **Save**.

    ![Adding storage account to the Stream Analytics job.](./media/stream-analytics-storage-account.png "Stream Analytics job storage account")

6. Below **Job topology**, select **Outputs**. Below **Add**, select **Azure Synapse Analytics**.

7. For the new output, provide the following details. Then, select **Save**.

    - **Output alias**: Use `asa-telco-output`, as this is what we will reference in the job definition query
    - Enable **Select SQL Database from your subscriptions**
    - Select the name of the dedicated pool you created earlier for **Database**
    - Use `telcodata` as the name of the **Table**

## Conclusion

In this blog post, you have seen how to query data from Cosmos DB in a Serverless SQL pool via the analytical store, a feature that eliminates the performance penalty of running complex queries on a high-volume transactional system. Moreover, you learned the T-SQL utilities available to query Parquet, CSV, and JSON files. Lastly, you configured a SQL dedicated pool, Streaming Analytics, and an Event Hub to simulate a streaming data example. Note that the streaming example is applicable to other domains, such as IoT.