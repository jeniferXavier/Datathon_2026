PADS Parkinson's Tremor Analysis Dashboard
1. Executive Summary
This project provides an end-to-end analytical pipeline for the PADS (Parkinson's Disease Smartwatch) dataset.
By processing high-frequency accelerometer and gyroscope signals, we identify objective biomarkers for tremor severity,
 bridging the gap between raw sensor data and clinical insights.
________________________________________
2.Dataset
Download dataset from this link,
🔗 Dataset Access: 
[PADS - Parkinsons Disease Smartwatch dataset v1.0.0
](https://physionet.org/content/parkinsons-disease-smartwatch/1.0.0/movement/)__
________________________________________
3. Technical Architecture
Key Metrics Calculated
•	RMS (Root Mean Square): Measures the physical intensity and magnitude of the tremor.
•	Dominant Frequency: Identifies the "speed" of the tremor in Hz.
•	Categorical Rating: Classifies tremors based on clinical thresholds.
Tool stack
•	Python: Primary engine for signal processing and data extraction.
•	PostgreSQL: Handles data relational integrity and de-identification.
•	Power BI: Delivers multi-dimensional visualizations across Axis, Sensor, and Demographics.
________________________________________
4. Repository Structure
Organizing your files this way ensures the judges can navigate your work easily:
•	📁 Data Extraction/ – DataDetectives03_Extract_JSON.ipynb (The core Python logic).
•	📁 Data Transformation/ – DataDetectives3_DataTransformation_SQL.sql (Create table script and restore data).
•	📁 Data Cleaning/- DataDetectives03_CleanedData.sql (DDL and DML scripts for PostgreSQL cleaning).
________________________________________
5.Deployment Guide
1.	Dataset: Download the PADS dataset.
2.	Processing: Execute the Jupyter Notebook to transform raw signals into summary features.
3.	Database: Import the resulting CSVs into your PostgreSQL environment using our SQL scripts.
