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
# Also remove age and over18, since we have a complete tenure history
# Also remove StandardHours, as that column is constant
# Also remove EmployeeCount, as that is a nonsense column
clean_data <- data  |> 
  mutate(Attrition = as.factor(ifelse(Attrition == "Yes", 1, 0)))  |> 
  # recode Gender as 1 = female, 0 otherwise
  mutate(Female = ifelse(Gender == "Female", 1, 0)) |> 
  # recode MaritalStatus as 1 = married, 0 otherwise
  mutate(Married = ifelse(MaritalStatus == "Married", 1, 0)) |> 
  # recode OverTime as 1 = yes, 0 otherwise
  mutate(WorkOT = ifelse(OverTime == "Yes", 1, 0)) |> 
  # recode level of education as years of postsecondary education
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
  # recode EducationField as series of dummies (ref = Life Sciences)
  mutate(EdFieldHR = as.factor(ifelse(EducationField == "Human Resources", 1, 0))) |> 
  mutate(EdFieldMktg = as.factor(ifelse(EducationField == "Marketing", 1, 0))) |> 
  mutate(EdFieldMed = as.factor(ifelse(EducationField == "Medical", 1, 0))) |> 
  mutate(EdFieldOth = as.factor(ifelse(EducationField == "Other", 1, 0))) |> 
  mutate(EdFieldTech = as.factor(ifelse(EducationField == "Technical Degree", 1, 0))) |> 
  # recode JobRole as a series of dummies (ref = Sales Executive)
  mutate(JobHCR = as.factor(ifelse(JobRole == "Healthcare Representative", 1, 0))) |>
  mutate(JobHR = as.factor(ifelse(JobRole == "Human Resources", 1, 0))) |>
  mutate(JobLab = as.factor(ifelse(JobRole == "Laboratory Technician", 1, 0))) |>
  mutate(JobMgr = as.factor(ifelse(JobRole == "Manager", 1, 0))) |>
  mutate(JobMfgDir = as.factor(ifelse(JobRole == "Manufacturing Director", 1, 0))) |>
  mutate(JobRschDir = as.factor(ifelse(JobRole == "Research Director", 1, 0))) |>
  mutate(JobRschSci = as.factor(ifelse(JobRole == "Research Scientist", 1, 0))) |>
  mutate(JobSalesRep = as.factor(ifelse(JobRole == "Sales Representative", 1, 0))) |>
  # jobs are redundant with department, except for Managers
  mutate(MgrDeptHR = ifelse(JobRole == "Manager" & Department == "Human Resources", 1, 0)) |> 
  mutate(MgrDeptRD = ifelse(JobRole == "Manager" & Department == "Research & Development", 1, 0)) |> 
  select_if(~!any(is.na(.))) |> 
  select(-Age, -BusinessTravel, -DailyRate, -Department, -Education, -EducationField, -EmployeeCount, -HourlyRate, -JobRole, -MonthlyRate, -Over18, -OverTime, -StandardHours)

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
