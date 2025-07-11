# employee-attrition-1
An application to predict attrition and use natural language to explain the results.

## The data
The dataset (./data/WA_Fn-UseC_-HR-Employee-Attrition.csv) is a fictitious group of IBM employees developed by the company for research purposes.  I downloaded it from Kaggle at https://www.kaggle.com/datasets/pavansubhasht/ibm-hr-analytics-attrition-dataset.  There are 1470 rows and 35 columns.

## global.R
This file invokes all required libraries, plus imports and cleans the CSV data.  The file is then split 80-20% into train and test sets, and a random forest classifier is trained on the training data.  Predictions are then generated on the test data.

## ui.R
The user interface.  The user is asked to select one of the test observations.  The employee's probability of attrition is displayed.

A button is also provided to invoke ChatGPT with the prompt "You are an HR analytics expert. Explain why this employee might leave: [insert employee data here]."  

## server.R
The backend server logic, primarily involving the function of the explanation button.  GPT 4.1-nano is invoked by default, since it is the cheapest (you can change this in the code if you wish).  If ChatGPT returns an HTTP error, that code is displayed in the window.  Otherwise, ChatGPT's explanation of what factors may lead to the employee turning over are provided to the window.
