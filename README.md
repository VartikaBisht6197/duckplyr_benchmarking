# R Data Transformation Benchmarking

This repository contains an R script designed to benchmark the performance of common data transformation operations using three different approaches: **Base R**, the popular **dplyr** package, and the high-performance **duckplyr** package.

## Overview

The script loads an extended version of the `mtcars` dataset (100,000 rows) and measures the execution time for various data manipulation tasks across these three methods. The goal is to visually demonstrate the performance differences, especially on larger datasets.

## Benchmarked Tasks

The following core data transformation operations are benchmarked:

* **Filter Rows**: Subsetting data based on a condition (e.g., cars with `mpg > 20`).

* **Select Columns**: Choosing specific columns from the dataset (e.g., `model`, `mpg`, `hp`).

* **Mutate Column**: Adding or modifying a column (e.g., converting `mpg` to `kpl`).

* **Group & Summarize**: Aggregating data based on groups (e.g., calculating average `mpg` by `cyl`).

* **Chained Operations**: Performing a sequence of transformations (e.g., filter then group then summarize).

## How it Works

1.  **Package Loading**: `dplyr`, `microbenchmark`, and `ggplot2` are loaded. `duckplyr` is loaded after `dplyr` benchmarks to ensure `dplyr`'s native performance is captured before `duckplyr` overrides its methods.

2.  **Data Preparation**: The `mtcars` dataset is expanded to 100,000 rows for more meaningful performance comparisons.

3.  **Benchmarking**: The `microbenchmark` package is used to run each operation multiple times and collect precise timing data for Base R, dplyr, and duckplyr.

4.  **Visualization**: The results are compiled into a single data frame, and a boxplot is generated using `ggplot2` to visually compare the performance across operations and methods.

5.  **Output**: The generated plot is saved as a PDF file named `mtcars_benchmarking_plot.pdf`.

## Requirements

* R (version 4.0 or higher recommended)

* R packages: `dplyr`, `duckplyr`, `microbenchmark`, `ggplot2` (install using `install.packages()`)

## Usage

1.  Save the R script (e.g., `benchmark_script.R`).

2.  Open RStudio or your preferred R environment.

3.  Run the script:

    ```
    source("benchmark_script.R")
    ```

4.  The benchmark results will be printed to the console, and a PDF plot will be saved in your working directory.
