# Olist E-Commerce Performance & Executive Insights (End-to-End SQL Pipeline)

## Project Overview
This repository contains an end-to-end data analytics project leveraging advanced SQL to transform raw, messy e-commerce transaction data into clean, structurally sound tables, culminating in a dual-tab executive dashboard. 

Instead of relying on external tools for data prep, 95% of the data lifecycle from aggressive data cleaning and handling missing records to complex analytical modeling was executed entirely within SQL.

## Data Engineering & Analytical Workload (SQL)
The SQL architecture was built to handle multiple relational tables, optimizing them for business intelligence reporting through the use of Common Table Expressions (CTEs), Window Functions, and complex Joins.

### 1. Data Cleaning & Pre-processing
- Handling Structural Anomalies: Identified and resolved inconsistent date-time stamps, missing data configurations, and ghost variables across primary transaction tables.
- Type Casting & Constraints: Standardized data types to maintain strict data integrity for revenue metrics and geographical identifiers.

### 2. Advanced Analytical Frameworks
- Market Basket Analysis (MBA): Built a transactional matrix using self-joins and aggregations to uncover the Product Combinations frequently bought together, identifying strong cross-selling opportunities.
- Logistics & Delivery Delay Bottlenecks: Applied window functions and date differentials to calculate late delivery volume clusters, isolating the exact state and city hubs causing fulfillment delays.
- Seller Risk Segmentation Matrix: Created a multi-variable quadrant system classifying merchants based on a rolling comparison of lifetime revenue vs. review scores. This separated High-Risk Sellers (needing instant operations attention) from Top/Potential sellers.

## Tech Stack
- Database Layer: SQL (Aggressive Data Cleaning, CTEs, Self-Joins, Window Functions, Conditional Logic).
- Visualization Layer: Tableau Desktop (Dual-tab executive layout utilizing custom collapsible filter panes).

## Live Interactive Dashboard
[ Click Here to View My Live Interactive Tableau Dashboard](https://public.tableau.com/views/OlistE-CommercePerformanceExecutiveInsight/OlistE-CommercePerformanceLogisticsDashboard?:language=en-GB&:sid=&:redirect=auth&:display_count=n&:origin=viz_share_link)
