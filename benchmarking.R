# R Script for Benchmarking Data Transformations
#
# This script is designed to compare the performance of data manipulation
# operations across three different R approaches:
#
# 1.  Base R: Using R's built-in functions and syntax.
# 2.  dplyr: A popular package for data manipulation, known for its
#     intuitive syntax and pipe operator (%>%).
# 3.  duckplyr: A package that provides a DuckDB backend for dplyr,
#     often offering significant performance improvements for larger datasets
#     by leveraging DuckDB's in-memory analytical database capabilities.
#
# The script performs the following common data transformation tasks:
#
#   +------------------+
#   |  Load Dataset    |  (e.g., mtcars, expanded to 100,000 rows)
#   +--------+---------+
#            |
#            v
#   +------------------+
#   |   Filter Rows    |  (e.g., keeping cars with 'mpg' > 20)
#   |   (Subset data)  |  Example: Find all cars with fuel efficiency above 20 miles per gallon.
#   +--------+---------+
#            |
#            v
#   +------------------+
#   |  Select Columns  |  (e.g., picking 'model', 'mpg', 'hp')
#   |  (Choose data)   |  Example: Keep only the car model, miles per gallon, and horsepower columns.
#   +--------+---------+
#            |
#            v
#   +------------------+
#   |   Mutate Column  |  (e.g., creating 'kpl' from 'mpg')
#   |  (Add/Modify data)|  Example: Convert miles per gallon (mpg) to kilometers per liter (kpl).
#   +--------+---------+
#            |
#            v
#   +------------------+
#   | Group & Summarize|  (e.g., calculating average 'mpg' by 'cyl')
#   |  (Aggregate data) |  Example: Calculate the average miles per gallon for cars grouped by their number of cylinders.
#   +--------+---------+
#            |
#            v
#   +------------------+
#   | Chained Operations| (e.g., Filter cars with 'hp' > 100, then group by 'cyl' and summarize average 'mpg')
#   |  (Sequential tasks)| Example: First, filter for powerful cars (horsepower > 100), then for these cars,
#   |                    |          calculate the average mpg for each cylinder count.
#   +--------+---------+
#            |
#            v
#   +------------------+
#   |   Benchmark      |  (Measure execution time for each method)
#   |   & Visualize    |  (Generate plot and save as PDF)
#   +------------------+
#

# 1. Load Required Libraries
load_package_silently <- function(pkg) {
  suppressPackageStartupMessages(
    tryCatch({
      library(pkg, character.only = TRUE)
      message(paste0("Package '", pkg, "' loaded successfully."))
    }, error = function(e) {
      stop(paste0("Failed to load package '", pkg, "'. Please install it."))
    })
  )
}

load_package_silently("dplyr")
load_package_silently("microbenchmark")
load_package_silently("ggplot2")

# 2. Load the Dataset
# We will use the built-in 'mtcars' dataset for this demonstration.
data(mtcars)

# Convert row names to a column for easier manipulation with dplyr/duckplyr
mtcars_df <- mtcars %>%
  tibble::rownames_to_column("model")

# Create a larger dataset for more meaningful benchmarks
# (mtcars is quite small, so differences might be negligible)
set.seed(123)
# Replicate 3125 times to get approximately 100,000 rows (32 * 3125 = 100,000)
large_mtcars_df <- do.call("rbind", replicate(3125, mtcars_df, simplify = FALSE))
message(paste("Benchmarking on a dataset with", nrow(large_mtcars_df), "rows."))


# 3. Define Transformation Operations and Benchmark
# Run all dplyr befor duckplyr as it overwrites dplyr methods with duckplyr methods.
# Initialize an empty list to store benchmark results
all_benchmarks_list <- list()

# Operation 1: Filter rows (e.g., cars with 'mpg' > 20)
# -----------------------------------------------------------------------------
message("\nBenchmarking Filter Operation (mpg > 20)...")
bm_filter_base_dplyr <- microbenchmark(
  base_R = large_mtcars_df[large_mtcars_df$mpg > 20, ],
  dplyr_filter = large_mtcars_df %>% filter(mpg > 20),
  times = 100 # Number of times to repeat each operation
)
all_benchmarks_list[["filter_base_dplyr"]] <- as.data.frame(bm_filter_base_dplyr) %>% mutate(Operation = "Filter")

# Operation 2: Select columns (e.g., 'model', 'mpg', 'hp')
# -----------------------------------------------------------------------------
message("\nBenchmarking Select Operation (model, mpg, hp)...")
bm_select_base_dplyr <- microbenchmark(
  base_R = large_mtcars_df[, c("model", "mpg", "hp")],
  dplyr_select = large_mtcars_df %>% select(model, mpg, hp),
  times = 100
)
all_benchmarks_list[["select_base_dplyr"]] <- as.data.frame(bm_select_base_dplyr) %>% mutate(Operation = "Select")

# Operation 3: Mutate/Add a new column (e.g., 'kpl' = 'mpg' * 0.425)
# -----------------------------------------------------------------------------
message("\nBenchmarking Mutate Operation (kpl = mpg * 0.425)...")
bm_mutate_base_dplyr <- microbenchmark(
  base_R = {
    temp_df <- large_mtcars_df
    temp_df$kpl <- temp_df$mpg * 0.425
    temp_df
  },
  dplyr_mutate = large_mtcars_df %>% mutate(kpl = mpg * 0.425),
  times = 100
)
all_benchmarks_list[["mutate_base_dplyr"]] <- as.data.frame(bm_mutate_base_dplyr) %>% mutate(Operation = "Mutate")

# Operation 4: Group by and Summarize (e.g., average mpg by 'cyl')
# -----------------------------------------------------------------------------
message("\nBenchmarking Group By and Summarize Operation (avg mpg by cyl)...")
bm_group_summarize_base_dplyr <- microbenchmark(
  base_R = aggregate(mpg ~ cyl, data = large_mtcars_df, FUN = mean),
  dplyr_group_summarize = large_mtcars_df %>%
    group_by(cyl) %>%
    summarise(avg_mpg = mean(mpg)),
  times = 100
)
all_benchmarks_list[["group_summarize_base_dplyr"]] <- as.data.frame(bm_group_summarize_base_dplyr) %>% mutate(Operation = "Group & Summarize")

# Operation 5: Chained Operations (Filter -> Group -> Summarize)
# -----------------------------------------------------------------------------
message("\nBenchmarking Chained Operations (Filter -> Group -> Summarize)...")
bm_chained_base_dplyr <- microbenchmark(
  base_R = {
    filtered_df <- large_mtcars_df[large_mtcars_df$hp > 100, ]
    aggregate(mpg ~ cyl, data = filtered_df, FUN = mean)
  },
  dplyr_chained = large_mtcars_df %>%
    filter(hp > 100) %>%
    group_by(cyl) %>%
    summarise(avg_mpg = mean(mpg)),
  times = 100
)
all_benchmarks_list[["chained_base_dplyr"]] <- as.data.frame(bm_chained_base_dplyr) %>% mutate(Operation = "Chained")


# --- Now, load duckplyr and benchmark duckplyr-optimized operations ---
# Loading duckplyr will automatically overwrite dplyr methods for optimization
library(duckplyr)

# Operation 1: Filter rows (duckplyr)
message("\nBenchmarking Filter Operation (mpg > 20) with duckplyr...")
bm_filter_duckplyr <- microbenchmark(
  duckplyr_filter = large_mtcars_df %>% filter(mpg > 20), # This will be duckplyr's version
  times = 100
)
all_benchmarks_list[["filter_duckplyr"]] <- as.data.frame(bm_filter_duckplyr) %>% mutate(Operation = "Filter")

# Operation 2: Select columns (duckplyr)
message("\nBenchmarking Select Operation (model, mpg, hp) with duckplyr...")
bm_select_duckplyr <- microbenchmark(
  duckplyr_select = large_mtcars_df %>% select(model, mpg, hp),
  times = 100
)
all_benchmarks_list[["select_duckplyr"]] <- as.data.frame(bm_select_duckplyr) %>% mutate(Operation = "Select")

# Operation 3: Mutate/Add a new column (duckplyr)
message("\nBenchmarking Mutate Operation (kpl = mpg * 0.425) with duckplyr...")
bm_mutate_duckplyr <- microbenchmark(
  duckplyr_mutate = large_mtcars_df %>% mutate(kpl = mpg * 0.425),
  times = 100
)
all_benchmarks_list[["mutate_duckplyr"]] <- as.data.frame(bm_mutate_duckplyr) %>% mutate(Operation = "Mutate")

# Operation 4: Group by and Summarize (duckplyr)
message("\nBenchmarking Group By and Summarize Operation (avg mpg by cyl) with duckplyr...")
bm_group_summarize_duckplyr <- microbenchmark(
  duckplyr_group_summarize = large_mtcars_df %>%
    group_by(cyl) %>%
    summarise(avg_mpg = mean(mpg)),
  times = 100
)
all_benchmarks_list[["group_summarize_duckplyr"]] <- as.data.frame(bm_group_summarize_duckplyr) %>% mutate(Operation = "Group & Summarize")

# Operation 5: Chained Operations (duckplyr)
message("\nBenchmarking Chained Operations (Filter -> Group -> Summarize) with duckplyr...")
bm_chained_duckplyr <- microbenchmark(
  duckplyr_chained = large_mtcars_df %>%
    filter(hp > 100) %>%
    group_by(cyl) %>%
    summarise(avg_mpg = mean(mpg)),
  times = 100
)
all_benchmarks_list[["chained_duckplyr"]] <- as.data.frame(bm_chained_duckplyr) %>% mutate(Operation = "Chained")


# 4. Visualize Results (Optional, but highly recommended)
# Combine all benchmark results into a single data frame for plotting
all_benchmarks <- bind_rows(all_benchmarks_list)

# Clean up expression names for better plotting
all_benchmarks$expr <- as.character(all_benchmarks$expr)
all_benchmarks$Method <- case_when(
  grepl("base_R", all_benchmarks$expr) ~ "Base R",
  grepl("dplyr", all_benchmarks$expr) ~ "dplyr",
  grepl("duckplyr", all_benchmarks$expr) ~ "duckplyr",
  TRUE ~ "Other"
)

# Plotting the results
# Convert time from nanoseconds to milliseconds for readability
all_benchmarks$time_ms <- all_benchmarks$time / 1e6

# Create the plot object
p <- ggplot(all_benchmarks, aes(x = Method, y = time_ms, fill = Method)) +
  geom_boxplot() +
  facet_wrap(~ Operation, scales = "free_y") +
  labs(
    title = "Benchmarking R Data Transformation Methods on mtcars",
    subtitle = paste("Dataset size:", nrow(large_mtcars_df), "rows"),
    y = "Time (milliseconds)",
    x = "Method"
  ) +
  theme_minimal() +
  theme(axis.text.x = element_text(angle = 45, hjust = 1)) +
  scale_y_log10() # Use log scale for y-axis if times vary greatly

# Save the plot as a PDF
ggsave("mtcars_benchmarking_plot.pdf", plot = p, width = 10, height = 7, units = "in")

message("\nPlot saved as 'mtcars_benchmarking_plot.pdf'")

