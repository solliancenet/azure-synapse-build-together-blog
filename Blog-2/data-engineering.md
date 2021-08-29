# Episode 2: Data Engineering with Azure Synapse Analytics

## Table of Contents

- [Episode 2: Data Engineering with Azure Synapse Analytics](#episode-2-data-engineering-with-azure-synapse-analytics)
  - [Table of Contents](#table-of-contents)
  - [Introduction](#introduction)
  - [Task 1: Create a new Storage Account](#task-1-create-a-new-storage-account)
  - [Task 2: Working with Linked Services](#task-2-working-with-linked-services)
  - [Task 3: Develop a Pipeline to Orchestrate Data Engineering Tasks](#task-3-develop-a-pipeline-to-orchestrate-data-engineering-tasks)
  - [Task 4: Explore the Copy Data Activity](#task-4-explore-the-copy-data-activity)
  - [Task 5: Get Started with Data Flows](#task-5-get-started-with-data-flows)
  - [Task 6: Create a Synapse Dedicated Pool and a Sink Table](#task-6-create-a-synapse-dedicated-pool-and-a-sink-table)
  - [Task 7: Configure the Sink Transformation](#task-7-configure-the-sink-transformation)
  - [Task 8: Orchestrate a Data Flow in a Pipeline](#task-8-orchestrate-a-data-flow-in-a-pipeline)
  - [Task 9: Conclusion](#task-9-conclusion)
  - [Note about Dedicated SQL Pools](#note-about-dedicated-sql-pools)

## Introduction

Data engineering encompasses a wide variety of tasks. These tasks include consolidating various structured and unstructured data into a format suitable for building analytical solutions. Data engineers use tools and languages available in Azure Synapse Analytics to explore data, design data storage, build pipelines and transformations, secure data, and ensure compliance. Data engineering also entails monitoring data workloads to identify failures and improve performance.

In this episode, you'll familiarize yourself with Azure Synapse Analytics while creating a data pipeline with data transformations to provide data into an analytics-ready queryable format.

## Task 1: Create a new Storage Account

We will create a simple pipeline with the Copy Data activity to copy data from a storage account to the Data Lake Storage Gen2 account linked to your Synapse Workspace in the following Tasks. We will start by creating a new Storage Account.

1. Navigate to the [Azure portal](portal.azure.com) and select **Create a resource**. Search for **Storage account** and select **Create**.

2. On the **Basics** tab of the **Create a storage account** page, provide the following parameters. Then, select **Review + create**.

    - **Subscription**: Use the same subscription that you provisioned your Workspace in
    - **Resource group**: Use the same resource group that you provisioned your Workspace in
    - **Storage account name**: Use a descriptive name, like `linkedblobstorage[SUFFIX]`
    - **Region**: Same as your Synapse Workspace
    - **Performance**: `Standard` will suffice
    - **Redundancy**: `Locally-redundant storage (LRS)` will suffice

    ![Creating a Storage Account according to the parameters above.](./media/provision-storage-account.png "Creating a new Storage Account")

3. Once validation passes, select **Create**.

4. Once the Storage Account provisions, select **Containers** below **Data storage**.

    ![Selecting Storage Account Containers in the Azure portal.](./media/select-containers.png "Storage Account Containers")

5. In the **New container** pane, enter `coviddata` as the name. Select **Create**.

6. Select the `coviddata` container and select **Upload** (1). Save locally and upload the [COVID-19 sample data](https://pandemicdatalake.blob.core.windows.net/public/curated/covid-19/bing_covid-19_data/latest/bing_covid-19_data.csv) (2). Then, select **Upload** (3).

    ![Uploading sample CSV data to the Blob Storage container.](./media/upload-sample-data.png "Uploading sample data")

    >**Note**: Due to the size of this file, it may take a few minutes to upload. The data in this ???

You have finished setting up the Storage Account. Now, you will create a *linked service* in Azure Synapse Analytics.

## Task 2: Working with Linked Services

A linked service defines the connection information for a resource, such as a storage account. In addition, it describes how to connect to data.

1. In your Synapse Workspace, select the **Manage** hub (1) and select **Linked services** (2). Select **+ New** (3).

    ![Creating a new linked service in the Manage hub.](./media/create-new-linked-service.png "Creating a new linked service")

2. In the **New linked service** window, search for and select **Azure Blob Storage**.

3. In the **New linked service (Azure Blob Storage)** window, provide the following parameters. Then, select **Create**.

    - **Name**: Use a descriptive name, like `linkedcovidstorageaccount`
    - **Authentication method**: Use `Account key`, though note the other, more secure options available
    - **Account selection method**: Select `From Azure subscription`
      - Provide the correct **Azure subscription** and the **Storage account name** of the storage account you just created

    ![Creating a storage account linked service in the Manage hub.](./media/new-linked-service.png "Storage account linked service")

As you created the linked service, note that you could specify the *integration runtime* to use. This allows you to dictate where compute resources are located to move data from a variety of sources. For example, instead of the default, cloud-hosted integration runtime, you can use a self-hosted integration runtime to move on-premises CSV data to the linked Azure Data Lake Storage Gen2 account.

## Task 3: Develop a Pipeline to Orchestrate Data Engineering Tasks

In this Task, we will leverage the Copy Data tool wizard to create a pipeline with a Copy data activity. This will allow us to explore the debugging and execution strategies available to data engineers through pipelines.

1. Navigate to the **Data** hub (1) and select the **Linked** tab (2). Expand **Azure Data Lake Storage Gen2** (3) and select the **users** container (4).

   ![Selecting the users container in the linked ADLS Gen2 account.](./media/select-users-container.png "Selecting users container")

2. Create a new folder and title it something descriptive, such as `CovidDataOutput`. This folder will be the sink for the Copy Data activity.

3. Navigate to the **Integrate** hub (1) and select the **Copy Data tool** (2). A wizard opens to create a *Copy Data Activity* orchestrated through a *pipeline*.

    ![Opening the Copy Data tool wizard.](./media/copy-data-tool.png "Copy Data tool in the Integrate hub")

4. On the **Properties** tab, select **Built-in copy task**. Then, select **Run once now**. Select **Next**.

    ![Properties tab of the Copy Data tool.](./media/properties-tab.png "Properties tab")

    >**Note**: The **Schedule** and **Tumbling window** options are trigger types, more on that in the next Task.

5. For the **Source data store** tab, provide the following information. Then, select **Next**.

    - **Source type**: Select `Azure Blob Storage`
    - **Connection**: Choose the linked service you created earlier
    - **File or folder**: Select **Browse**
      - Choose the `coviddata` path and select **OK**
    - Select **Binary copy** to copy the data as-is (no rigid schemas enforced)
      - Set **Compression type** to **None**
    - Select **Recursively** to enable recursive copying (though it is not applicable in this sample)

    ![Source data store parameters for the Copy Data tool.](./media/source-data-store.png "Source data store parameters")

6. For the **Destination data store** tab, provide the following information. Select **Next**.

    - **Target type**: Select `Azure Data Lake Storage Gen2`
    - **Connection**: Choose the linked service that appears
    - **Folder path**: Select **Browse**
      - Choose `users/CovidDataOutput` and select **OK**

    ![Specifying the destination data store in the linked ADLS Gen2 account.](./media/destination-data-store.png "Specifying destination data store in ADLS Gen2")

7. On the **Settings** tab, provide the following information and select **Next**.

    - **Task name**: Provide something descriptive, such as `CovidDataCopyPipeline`. This value is also used as the pipeline name

    ![Providing the pipeline name in the Settings tab of the Copy Data tool.](./media/copy-data-activity.png "Settings tab of the Copy Data wizard")

8. On the **Summary** tab, observe the Copy Data activity summary. In particular, note the references to source and destination datasets. Validate the summary, then select **Next**.

    ![Copy Data activity summary in the Copy Data tool wizard.](./media/source-and-target-datasets.png "Copy Data activity summary")

9. On the next tab, Synapse will publish the two datasets and the pipeline. It will also execute the pipeline. Once execution completes, observe the published assets by selecting **Edit Pipeline**.

    ![Copy Data deployment and pipeline execution in the Copy Data tool wizard.](./media/pipeline-execution-complete.png "Copy Data wizard deployment complete")

In the subsequent Tasks, we will explore the assets produced by the Copy Data wizard. We will also discuss Data Flows and the control flow mechanisms available.

On a separate note, developers often use version control tools and CI/CD to test and deploy production builds of a product faster. Synapse provides a similar feature through the **Git configuration** functionality accessible in the **Manage** hub. Leveraging this feature means that Workspace assets are stored as JSON files in the linked repository allowing data engineers to move their data assets between environments reliably.

## Task 4: Explore the Copy Data Activity

1. Once the pipeline opens in the **Integrate** hub, select the **Copy data** activity.

    ![Copy Data activity in the pipeline in the Integrate hub.](./media/copy-data-activity-integrate-hub.png "Copy Data activity in Integrate hub")

2. Observe the **Source** tab. Notice the reference to the source dataset. In this case, it is a binary dataset, meaning that it does not model the schema of the file(s) it represents. Notice the use of a wildcard path; this matches all files in the `coviddata` container; thus, we’ll be moving all the files. You are not required to define a specific file to move in the Copy Data wizard.

    ![Copy Data activity Source settings.](./media/source-tab-copy-data.png "Source settings")

3. The **Sink** tab references the target dataset, which is also a binary dataset.

    ![Copy Data activity Sink settings.](./media/destination-tab-copy-data.png "Sink settings")

4. Now that you observe the features of the Copy data activity, select **Debug** at the top of the page. The Debug functionality allows you to test your pipelines as you develop them, whereas using a trigger to orchestrate your pipeline uses the latest published configuration.

5. Once the Debug session completes, select the **Output** tab (note that you may have to deselect the Copy data activity). Note that you can visualize the input (1), the output (2), and the details of the activity (3).

    ![Debug run of the Copy Data activity.](./media/input-output-summary-debug.png "Debug run")

6. Besides debugging, you can also select **Add trigger**. Select **New/Edit**. Then, in the **Choose trigger...** dropdown, select **+ New**.

7. In the **New trigger** window, note that you can provide the following trigger types. Creating a trigger is out of scope for this post.

    - **Schedule** triggers: Repeatedly execute after the specified interval (**Recurrence**), starting from the **Start date** and continuing to an optional **End date**
    - **Tumbling window** triggers: Similar to **Schedule** triggers, but consider pipeline execution status in their state (e.g., they are aware that the pipeline they are associated with is canceled or otherwise interrupted)
    - **Storage event** triggers: Fire whenever a blob is created or deleted in the specified Blob Storage container
    - **Custom event** triggers: Integrate with Azure Event Grid to fire based on a subscription to a topic

    ![Sample Schedule trigger.](./media/create-trigger.png "Schedule trigger")

## Task 5: Get Started with Data Flows

Data is never perfect. Part of data engineering is data preparation; this includes the cleaning and transformation of data. Data preparation is accomplished using various code-based (Spark, SQL) or code-free methods. In this task, we investigate data flows as part of a code-free approach to data preparation.

1. Navigate to the `CovidDataOutput` directory that you created in Task 3, Step 2. Select the `bing_covid-19_data.csv` file that has been moved into the Data Lake from Blob Storage. Then, select **New data flow**.

    ![Creating a Data Flow from a CSV file in ADLS Gen2.](./media/create-data-flow-from-csv.png "Data Flow from a CSV file")

2. Before creating the Data Flow, Azure will prompt you with multiple parameters. Enter them, and then select **Create**.

    - **Data flow name**: `TransformCovidData`
    - **Integration dataset name**: `CovidCSVDataset`
    - **Format**: Select **DelimitedText**
    - **Import schema**: Select **From connection/store**

    ![Specify integration dataset and data flow parameters.](./media/create-integration-dataset-for-df.png "Integration dataset and data flow parameters")

3. Once the Data Flow editor launches, select the slider for **Data flow debug**. Accept the default settings and select **OK**. Using this feature will help you visualize how the various steps of your data flow manipulate data.

4. Select the `source1` source transformation. On the **Source settings** tab (1), select **Open** next to the **Dataset** (2).

    ![Open the integration dataset on the source transformation.](./media/open-source-dataset.png "Open integration dataset")

5. On the **Connection** tab of the `CovidCSVDataset` integration dataset, select **First row as header**. Return to the `TransformCovidData` Data Flow.

6. Select the `source1` source transformation again. Navigate to the **Projection** tab (1). Select **Import projection** (2).

    ![Import projection button on the source transformation.](./media/import-projection.png "Import projection button")

7. Note how Azure uses the Data Flow debugging cluster to populate column names and infer column types. This technology is powered by a Spark engine. For the `updated` column, set the **Format** to `yyyy-MM-dd`.

    ![Observe the column projection and change the updated column format.](./media/csv-projection-correct-format.png "Column projection")

8. Navigate to the **Data preview** tab. The Data Flow debugging cluster allows you to visualize how the source transformation modifies the data.

    >**Note**: You may need to select **Refresh** for accurate results to show. 

9. Note that the **Data preview** tab supports some basic analysis. Select the `country_region` column and select **Statistics**. Since the unique values of the 1,000 rows data preview are just `Worldwide` and `Afghanistan`, this column may not be useful for our data analysis.

    ![Examining the country_region column in the Data Preview.](./media/data-preview.png "country_region column")

    >**Note**: It's possible to increase the data preview beyond 1,000 rows for a more comprehensive analysis of the data.

10. Select the small **+** below the source transformation. Below **Schema modifier**, select **Select**.

    ![Add the Select schema modifier.](./media/select-schema-modifier.png "Select schema modifier")

11. In the **Select settings** tab, notice how the columns from the source dataset are imported into the Select schema modifier. Delete the `id` and `load_time` columns, as they are not relevant to our analysis.

    >**Note**: To read more about what the columns of this dataset represent, read the [documentation](https://docs.microsoft.com/azure/open-datasets/dataset-bing-covid-19) for this dataset.

    ![Remove unnecessary columns using the Select schema modifier.](./media/select-certain-columns.png "Remove unnecessary columns")

12. Select the small **+** below the column select transformation. Below **Schema modifier**, select **Aggregate**.

    ![Add the Aggregate schema modifier.](./media/aggregate-schema-modifier.png "Aggregate schema modifier")

13. In the **Aggregate settings** tab, select the **Group by** switch (1). Use `updated` as the column name (2). Accept the default **Name as** value.

    ![Set the Group by settings for the Aggregate schema modifier.](./media/updated-group-by-column.png "Group by settings")

14. Select the **Aggregates** switch (1). Title the **Column** `ChangeFromYesterdayAsPercentOfToday` and set the **Expression** to `(sum(confirmed_change)/sum(confirmed)) * 100` (2).

    ![Set the Aggregate setting for the Aggregate schema modifier.](./media/aggregate-schema-modifier-aggregate-func.png "Aggregate settings")

You have built a majority of the Data Flow. Now, you need to configure a sink to store the output data from the aggregate activity.

## Task 6: Create a Synapse Dedicated Pool and a Sink Table

In this Task, you will gain an introduction to how to configure a dedicated SQL pool as a sink for a Data Flow. If this is your first time working with a dedicated SQL pool, do not be overwhelmed. Think of it as a set of provisioned resources that run analytics queries in a distributed manner. You will gain more exposure to dedicated SQL pools as you read the next blog posts.

1. Navigate to the **Manage** hub (1). Select **SQL pools** (2). Then, select **+ New**.

    ![Navigating to the Manage hub to create a new SQL pool.](./media/create-sql-pool.png "Creating a new SQL pool in the Manage hub")

2. In the **New dedicated SQL pool** window, provide the following details and select **Review + create**.

    - **Dedicated SQL pool name**: `DataFlowOutputPool`
    - **Performance level**: `DW100c`

    ![Configuring the DataFlowOutputPool dedicated SQL pool.](./media/sql-pool-params.png "DataFlowOutputPool dedicated SQL pool parameters")

3. Select **Create** once validation finishes.

4. Once provisioning completes, navigate to the **Develop** hub and select **SQL script**.

    ![Creating a SQL script in the Develop hub.](./media/create-sql-script.png "Creating a SQL script")

5. After ensuring that you are connected to the `DataFlowOutputPool`, provide the following SQL script and select **Run**.

    ```sql
    CREATE TABLE AggregatedCovidData (
        updated DATE NOT NULL,
        ChangeFromYesterdayAsPercentOfToday decimal(6, 3) NULL
    );
    ```

    ![Create dbo.AggregatedCovidData table in the DataFlowOutputPool database.](./media/create-sink-table.png "Creating sink AggregatedCovidData table")

## Task 7: Configure the Sink Transformation

Now that you have created the sink table, finalize the Data Flow. To do this, you will first create an Integration dataset for the `AggregatedCovidData` table.

1. Navigate back to the Data Flow you began earlier (`TransformCovidData`). Add a new data **Sink**.

    ![Adding a sink to the Data Flow.](./media/data-destination.png "Adding sink transformation")

2. On the **Sink** tab (1), next to **Dataset**, select **+ New** (2).

    ![Create a new Integration dataset from the Sink tab.](./media/select-integration-dataset-sink.png "New Integration dataset")

3. In the **New integration dataset** window, select **Azure Synapse Analytics**. Then, select **Continue**.

4. In the **Set properties** window, provide the following parameters. Then, select **OK**.

    - **Name**: `SQLSink`
    - **Linked service**: Choose the default that is bundled with your workspace
    - Choose the **Select from existing table** option
      - Select the **Edit** checkbox and enter `dbo.AggregatedCovidData` as the name
    - Select **From connection/store** for **Import schema**

    ![Set the properties for the new Integration dataset.](./media/sql-sink-properties.png "Set integration dataset properties")

5. Now, configure the **DBName** parameter. Set it to `DataFlowOutputPool`. Select **OK**.

    ![Populate the DBName parameter with DataFlowOutputPool.](./media/set-dbname-parameter.png "Populate the DBName parameter")

6. The Azure Synapse Workspace experience will return you to the Data Flow. On the **Sink** tab, feel free to select **Test connection**. Ensure that it succeeds.

    >If it fails, select **Open** next to the **SQLSink** integration dataset. Ensure that the **DBName** parameter is set.
    >
    >![Verify that the DBName parameter is set for the Integration dataset.](./media/set-dbname-parameter-integration-dataset.png "Observe the populated DBName parameter in the Integration dataset")

7. Navigate to the **Data preview** tab. Observe the preview data for the `updated` and `ChangeFromYesterdayAsPercentOfToday` columns. Note that you may need to **Refresh** the view first.

    ![Preview data for the sink transformation.](./media/sink-data-preview.png "Preview data persisted to the dedicated SQL pool")

8. Navigate to the **Mapping** tab. Observe the error that appears. It occurs because the sink dataset column is of type `decimal(6, 3)`, but the output of the aggregate modifier is a `long`.

    ![Observe the type mapping error.](./media/mapping-types-error.png "Type mapping error")

    >**Note**: If you do not see the error, ensure that **Validate schema** is checked on the **Sink** tab.

9. To fix this, add a **Derived Column** schema modifier between the Aggregate and Sink modifiers.

10. In the **Derived column's settings** tab, set the **Column** to `CastPercentageChanged`. Then, set the expression to `toDecimal(ChangeFromYesterdayAsPercentOfToday, 6, 3)`.

    ![Create a CastPercentageChanged column of type decimal(6,3).](./media/derived-column-for-casting.png "Create cast derived column")

    Note that because we are using a derived column modifier, the modifier is creating a new column based on casting the `ChangeFromYesterdayAsPercentOfToday` column to a `decimal`.

11. Return to the sink modifier. Navigate to the **Mapping** tab (1). Disable **Auto mapping** (2). Map the derived `CastPercentageChanged` column to the Data Warehouse table `ChangeFromYesterdayAsPercentOfToday` column (3). Note that the error disappears.

    ![Map CastPercentageChanged to ChangeFromYesterdayAsPercentOfToday.](./media/successful-type-conversion.png "Update the sink column mapping")

12. Publish all Workspace changes.

## Task 8: Orchestrate a Data Flow in a Pipeline

As you developed a Data Flow in the previous tasks, all data modification was performed in memory--the transformed data was not persisted to the dedicated SQL pool output. We will invoke the Data Flow from a Pipeline in this task to write the data to the dedicated SQL pool. 

1. In the **Integrate** hub, select **Pipeline**.

    ![Create a new Pipeline in the Integrate hub.](./media/integrate-hub-create-pipeline.png "New Pipeline in the Integrate hub")

2. Below **Activities**, expand **Move & transform** (1). Drag a **Data flow** activity into the pipeline editor (2).

    ![Add a Data Flow activity to the Pipeline.](./media/data-flow-in-pipeline.png "Add activity to Pipeline")

3. In the **Settings** tab, provide the following details.

    - **Data flow**: `TransformCovidData`
    - Expand **Staging**
      - Choose the default linked service for ADLS Gen2 as the **Staging linked service**
    - Provide a **Staging storage folder**. You can use a path such as `[WORKSPACE FILE SYSTEM]/staging`
    - Keep all other values at their defaults

    ![Configure the Data Flow activity execution settings.](./media/data-flow-debug-settings.png "Configure activity execution")

4. **Debug** the Pipeline, as shown in Task 4.

5. Wait for the pipeline to finish executing, as indicated by the **Output** tab.

    ![Verify that Pipeline execution completes.](./media/pipeline-run-success.png "Pipeline execution complete")

6. Navigate to the **Monitor** hub (1). Below **Integration**, select **Pipeline runs** (2). Locate the pipeline you executed (3). I ran the pipeline multiple times.

    ![Select the Pipeline run from the Monitor hub.](./media/locate-pipeline-run-monitor-hub.png "Select pipeline run")

7. On the Pipeline run page, observe the Data Flow activity. Note that you can also view the details of the run by selecting the glasses icon.

    ![View Pipeline run details in the Monitor hub.](./media/view-pipeline-details.png "Pipeline run details")

    ![View specific steps in the Pipeline Data Flow.](./media/data-flow-run-from-monitor-hub.png "Specific data transformations in Data Flow")

Congratulations. You have just created a pipeline to orchestrate a Data Flow. Remember that you can use triggers to automate your pipelines, as discussed during our exploration of the Copy Data activity.

## Task 9: Conclusion

Often, data sources come in a variety of formats. Luckily, by using the code-free Copy Data and Data Flow activities in a pipeline, you have the flexibility to move and transform your data for your business needs.

Note that there are a variety of features supported in Data Flows. For example, users of SSIS will recognize [branches](https://docs.microsoft.com/azure/data-factory/data-flow-new-branch) to create parallel data transformation paths. For example, in our pipeline, if we wanted to write the output of the Select modifier to Parquet files stored in Azure Data Lake Storage Gen2, that is easily accomplished.

Lastly, remember that you have multiple options to execute your pipelines in development or production environments. In development, you can debug pipelines, while in production, you can create triggers.

## Note about Dedicated SQL Pools

In this post, we discussed how to provision a dedicated SQL pool. Note that dedicated SQL pools are billed as long as resources are provisioned. To minimize costs, delete or Pause the dedicated SQL pools you create. You can do this under the **Analytics pools** section of the **Manage** hub.

![Pause a dedicated SQL pool in the Manage hub.](./media/pause-pools.png "Pause dedicated SQL pools to minimize costs")
