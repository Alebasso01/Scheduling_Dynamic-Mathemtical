# Dynamic_and_Math_Scheduling

This project focuses on scheduling N jobs across 3 parallel machines, optimizing the process to minimize the number of late jobs. It is implemented in **MATLAB** and compares the performance of two approaches:  
1. **Dynamic Programming**  
2. **Mathematical Programming**

## Project Overview

The jobs are generated randomly with the following parameters:  
- **ID**: unique identifier.  
- **Arrival Time**: time when the job arrives.  
- **Due Date**: deadline for the job.  
- **Processing Time 1**: duration required to complete the job on machine 1.
- **Processing Time 2**: duration required to complete the job on machine 2.
- **Processing Time 3**: duration required to complete the job on machine 3.  

The job data is stored in a relational SQL database and used by the scheduling algorithms.  

Each algorithm computes the optimal job sequence, producing:  
- Tables containing the optimal sequence for each approach.  
- Gantt charts to visually represent the execution order.  

Finally, the `comparison_results` file compares the performance of the two algorithms.

## Windows Users

1. **Database Setup**:
  - Install **SQL Server Management Studio (SSMS)** for database management.
  - Use **Microsoft Azure** to create the relational SQL database.
    
2. **MATLAB Configuration**:
  - Open MATLAB and install the required toolboxes via the **Add-Ons** menu.
  - Use the **Database Explorer** app to configure a connection with your Azure database.
  - Ensure the `ODBC Data Source Administrator` is properly set up for communication between MATLAB and Azure SQL.
    
3. **Drivers**:
  - Install the latest **ODBC Driver for SQL Server**.
    
4. **Optional**:
  - Use **PowerShell** to interact with Azure if needed for advanced configurations.

## MacOS Users

1. **Database Setup**:
  - Use the **Azure web portal** to create the relational SQL database.
  - Install **Azure Data Studio** for database management.
    
2. **MATLAB Configuration**:
  - Open MATLAB and install the required toolboxes via the **Add-Ons** menu.
  - Use the **Database Explorer** app to configure a connection with your Azure database.
  - Ensure you have the **ODBC Manager for macOS** installed and configured to connect to Azure SQL.
    
3. **Drivers**:
  - Install the latest **ODBC Driver for SQL Server** for macOS.

## Requirements

### MATLAB
To run this project, ensure the following toolboxes and apps are added to your MATLAB installation:  
- Database Toolbox
- Optimization Toolbox
- Gantt Chart for Scheduling Problems
- Maximally Distinct Color Generator**  
- Legend Unq  

### Database 
- Azure Data Studio for managing the database.  
- Relational SQL Database (e.g., Azure SQL).  

## How to Use the Project

1. **Generate Job Data**:  
   Run the `initialization.m` file to automatically create job data and upload it to the database.

2. **Run the Algorithms**:  
   - Execute the algorithm files to calculate the optimal sequence.  
   - View the results through the Gantt charts.  

3. **Compare Results**:  
   Use `comparison_results.m` to compare the performance of both approaches.

## Acknowledgments

This project was developed to analyze and improve scheduling methodologies as part of the academic exam [Industrial Automation](https://corsi.unige.it/off.f/2021/ins/51470) during Master's degree in Computer Engineering at the University of Genova.

---


