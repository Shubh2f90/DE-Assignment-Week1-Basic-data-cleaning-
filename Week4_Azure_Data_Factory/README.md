# Week 4 - Azure Data Factory Pipeline Project

## Objective
Build an end-to-end data pipeline using Azure Storage Account and Azure Data Factory (ADF).

## Dataset
Sample - Superstore.csv

## Azure Resources Used

- Azure Resource Group
- Azure Storage Account
- Azure Blob Container
- Azure Data Factory (ADF)
- IAM Role Assignments

## Tasks Completed

### Task 1: Resource Group Creation
Created Resource Group:
- Name: Rg-DataEngineering
- Region: Central India

### Task 2: Storage Setup
Created:
- Storage Account: ststoresshubham
- Blob Container: raw-data

Uploaded:
- Sample - Superstore.csv

### Task 3: Azure Data Factory Setup
Created:
- ADF Instance: ADF-Shubham16

Configured:
- Linked Service
- Source Dataset
- Destination Dataset

### Task 4: Pipeline Development
Activities Used:
- Get Metadata
- Copy Data

Pipeline:
Get Metadata → Copy Data

### Task 5: Pipeline Execution
Successfully executed pipeline using Debug Run.

Results:
- Metadata validated
- 9994 rows copied successfully
- output.csv generated

### Task 6: IAM Role Assignment
Assigned:
- Reader
- Contributor
- Storage Blob Data Contributor

## Mini Project
Built an end-to-end Azure Data Factory pipeline that copies data from Blob Storage source to destination after metadata validation.

## Outcome
Successfully implemented and executed a complete Azure Data Factory pipeline using Azure cloud services.

## Author
Shubham Sharma
Celebal Technologies Internship 2026
