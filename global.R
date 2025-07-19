# Load required libraries
library(shiny)
library(bslib)
library(tidyverse)
library(randomForest)
library(httr)
library(jsonlite)
library(caret)
library(markdown)
library(DT)

# Load dataset (downloaded from Kaggle)
data <- read_csv("./data/WA_Fn-UseC_-HR-Employee-Attrition.csv")

# Preprocess data & feature engineering, remove redundant pay factors
# Also remove age and over18, since we have a complete tenure history
# Also remove StandardHours, as that column is constant
# Also remove EmployeeCount, as that is a nonsense column
clean_data <- data  |> 
  mutate(Attrition = as.factor(ifelse(Attrition == "Yes", 1, 0)))  |> 
  # recode Education as years of postsecondary education
  mutate(YrsPost12Ed = case_when(
    Education == 1 ~ 0,
    Education == 2 ~ 2,
    Education == 3 ~ 4,
    Education == 4 ~ 6,
    Education == 5 ~ 8)) |> 
  # recode BusinessTravel as an ordinal number
  mutate(TravelAmt = case_when(
    BusinessTravel == "Non-Travel" ~ 0,
    BusinessTravel == "Travel_Rarely" ~ 1,
    BusinessTravel == "Travel_Frequently" ~ 2)) |> 
  # cast EducationField, Gender, JobRole, MaritalStatus, Overtime as factors
  mutate(EdField = as.factor(EducationField)) |> 
  mutate(Sex = as.factor(Gender)) |>
  mutate(Job = as.factor(JobRole)) |>
  mutate(Married = as.factor(MaritalStatus)) |>
  mutate(WorkOT = as.factor(OverTime)) |>
  # jobs are redundant with department, except for Managers (ref = Sales)
  mutate(MgrDept = as.factor(ifelse(JobRole == "Manager", Department, "Not a Manager"))) |> 
  select_if(~!any(is.na(.))) |> 
  select(-Age, -BusinessTravel, -DailyRate, -Department, -Education, -EducationField, -EmployeeCount, -Gender, -HourlyRate, -JobRole, -MaritalStatus, -MonthlyRate, -Over18, -OverTime, -StandardHours)
  
# create benchmark averages by job role for prompt engineering
benchmarks <- clean_data |> 
  group_by(Job) |> 
  summarize(DistanceFromHome = mean(DistanceFromHome),
            EnvironmentSatisfaction = mean(EnvironmentSatisfaction),
            JobInvolvement = mean(JobInvolvement),
            JobLevel = mean(JobLevel),
            JobSatisfaction = mean(JobSatisfaction),
            MonthlyIncome = mean(MonthlyIncome),
            NumCompaniesWorked = mean(NumCompaniesWorked),
            PercentSalaryHike = mean(PercentSalaryHike),
            PerformanceRating = mean(PerformanceRating),
            RelationshipSatisfaction = mean(RelationshipSatisfaction),
            StockOptionLevel = mean(StockOptionLevel),
            TotalWorkingYears = mean(TotalWorkingYears),
            TrainingTimesLastYear = mean(TrainingTimesLastYear),
            WorkLifeBalance = mean(WorkLifeBalance),
            YearsAtCompany = mean(YearsAtCompany),
            YearsInCurrentRole = mean(YearsInCurrentRole),
            YearsSinceLastPromotion = mean(YearsSinceLastPromotion),
            YearsWithCurrManager = mean(YearsWithCurrManager),
            YrsPost12Ed = mean(YrsPost12Ed))

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

# Importance dataset - sort by descending Gini Index
imp_tbl <- rf_fit$importance |> 
  as.data.frame() |> 
  arrange(desc(MeanDecreaseGini)) |> 
  select(MeanDecreaseGini)

# create a vector of sorted feature names
vars_by_imp <- ""
for (i in 1:nrow(imp_tbl)){
  if (i == 1){
    vars_by_imp <- rownames(imp_tbl)[i]
  } else {
    vars_by_imp <- paste0(vars_by_imp, ", ", rownames(imp_tbl)[i])
  }
}
