# Episode 4: Serverless Data Lake Exploration and Streaming Analytics

## Table of Contents

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

1. On the **Data** hub, select the **Linked** tab (1). Expand **Azure Cosmos DB** and the **RetailSalesDemoDB** (2) linked service. Notice how the three containers you created in the previous task are indicated, along with an annotation showing that the analytical store is enabled.

    ![Analytical Store-enabled Cosmos DB containers in the Synapse Workspace.](./media/analytical-store-containers.png "Analytical Store-enabled containers")

## Task 4: Introduction to Serverless SQL Pools

Serverless SQL Pools allow data engineers to query their data without managing compute clusters or the elasticity of those clusters (scaling in response to the workload). While this model is extremely flexible, customers desire controlling the costs of their Azure resources. This Task demonstrates how users of Serverless SQL pools can set usage limits.

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

## Conclusion