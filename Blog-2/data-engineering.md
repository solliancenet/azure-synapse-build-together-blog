# Episode 2: Data Engineering with Azure Synapse Analytics

## Table of Contents

## Task 1: Create a new Storage Account

In the following Tasks, we will create a simple pipeline with the Copy Data activity to copy data from a storage account to the Data Lake Storage Gen2 account linked to your Synapse Workspace. We will start by creating a new Storage Account.

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

    >**Note**: Due to the size of this file, it may take a few minutes to upload. The file was pulled directly from Azure Open Datasets.

You have finished setting up the Storage Account. Now, you will create a *linked service* in Azure Synapse Analytics.

## Task 2: Working with Linked Services

A linked service defines the connection information for a resource, such as a storage account. It defines how to connect to data.

1. In your Synapse Workspace, select the **Manage** hub (1) and select **Linked services** (2). Select **+ New** (3).

    ![Creating a new linked service in the Manage hub.](./media/create-new-linked-service.png "Creating a new linked service")

2. In the **New linked service** window, search for and select **Azure Blob Storage**.

3. In the **New linked service (Azure Blob Storage)** window, provide the following parameters. Then, select **Create**.

    - **Name**: Use a descriptive name, like `linkedcovidstorageaccount`
    - **Authentication method**: Use `Account key`, though note the other, more secure options available
    - **Account selection method**: Select `From Azure subscription`
      - Provide the correct **Azure subscription** and the **Storage account name** of the storage account you just created

    ![Creating a storage account linked service in the Manage hub.](./media/new-linked-service.png "Storage account linked service")

As you created the linked service, note that you had the option to specify the *integration runtime* to use. This allows you dictate where compute resources are located to move data from a variety of sources. For example, instead of the default, cloud-hosted integration runtime, you can use a self-hosted integration runtime to move on-premises CSV data to the linked Azure Data Lake Storage Gen2 account.

## Task 3: Develop a Pipeline to Orchestrate Data Engineering Tasks

In this Task, we will leverage the Copy Data tool wizard to create a pipeline with a Copy data activity. This will allow us to explore the debugging and execution strategies available to data engineers through pipelines.

1. Navigate to the **Integrate** hub (1) and select the **Copy Data tool** (2). This will open a wizard to create a *Copy Data Activity* orchestrated through a *pipeline*.

    ![Opening the Copy Data tool wizard.](./media/copy-data-tool.png "Copy Data tool in the Integrate hub")

2. On the **Properties** tab, select **Built-in copy task**. Then, select **Run once now**. Select **Next**.

    ![Properties tab of the Copy Data tool.](./media/properties-tab.png "Properties tab")

3. For the **Source data store** tab, provide the following information:
   
    - **Source type**: Select `Azure Blob Storage`
    - **Connection**: Choose the linked service you created earlier
    - **File or folder**: Select **Browse**
      - Choose the `coviddata` path and select **OK**
    - Select **Binary copy** to copy the data as-is (no rigid schemas enforced)
      - Set **Compression type** to **None**
    - Select **Recursively** to enable recursive copying (though it is not applicable in this sample) 

    ![Source data store parameters for the Copy Data tool.](./media/source-data-store.png "Source data store parameters")
