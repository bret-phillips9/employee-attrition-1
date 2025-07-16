# Load required libraries
library(shiny)
library(bslib)
library(tidyverse)
library(randomForest)
library(shinydashboard)
library(httr)
library(jsonlite)
library(caret)

# Load dataset (downloaded from Kaggle)
data <- read_csv("./data/WA_Fn-UseC_-HR-Employee-Attrition.csv")

# Preprocess data & feature engineering, remove redundant pay factors
# Also remove age, since we have a complete tenure history
# Also remove EmployeeCount, as that is a nonsense column
clean_data <- data  |> 
  mutate(Attrition = as.factor(ifelse(Attrition == "Yes", 1, 0)))  |> 
  # recode level of education as years of postsecondary education
  mutate(YrsPost12Ed = case_when(
    Education == 1 ~ 0,
    Education == 2 ~ 2,
    Education == 3 ~ 4,
    Education == 4 ~ 6,
    Education == 5 ~ 8)) |> 
  # recode EducationField as series of dummies (ref = Life Sciences)
  mutate(EdFieldHR = as.factor(ifelse(EducationField == "Human Resources", 1, 0))) |> 
  mutate(EdFieldMktg = as.factor(ifelse(EducationField == "Marketing", 1, 0))) |> 
  mutate(EdFieldMed = as.factor(ifelse(EducationField == "Medical", 1, 0))) |> 
  mutate(EdFieldOth = as.factor(ifelse(EducationField == "Other", 1, 0))) |> 
  mutate(EdFieldTech = as.factor(ifelse(EducationField == "Technical Degree", 1, 0))) |> 
  select_if(~!any(is.na(.))) |> 
  select(-Education, -DailyRate, -MonthlyRate, -HourlyRate, -EmployeeCount, -Age, -EducationField)

# Train model
set.seed(123)
train_idx <- sample(nrow(clean_data), 0.8 * nrow(clean_data))
train <- clean_data[train_idx, ]
test <- clean_data[-train_idx, ]

rf_fit <- randomForest(Attrition ~ . -EmployeeNumber,
                       data = train, importance = TRUE, ntree = 100)

# Generate test predictions
test$attrit_pred <- predict(rf_fit, test)

# Confusion matrix
cm_tbl <- table(predicted = test$attrit_pred, actual = test$Attrition)
