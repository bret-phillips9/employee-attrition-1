# Load required libraries
library(shiny)
library(bslib)
library(tidyverse)
library(randomForest)
library(shinydashboard)
library(httr)
library(jsonlite)

# Load dataset (downloaded from Kaggle)
data <- read_csv("./data/WA_Fn-UseC_-HR-Employee-Attrition.csv")

# Preprocess data
clean_data <- data  |> 
  mutate(Attrition = as.factor(ifelse(Attrition == "Yes", 1, 0)))  |> 
  select_if(~!any(is.na(.)))

# Train model
set.seed(123)
train_idx <- sample(nrow(clean_data), 0.8 * nrow(clean_data))
train <- clean_data[train_idx, ]
test <- clean_data[-train_idx, ]

rf_fit <- randomForest(Attrition ~ Age + JobSatisfaction + MonthlyIncome + OverTime + TotalWorkingYears + YearsAtCompany,
                       data = train, importance = TRUE, ntree = 100)

