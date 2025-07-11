dashboardPage(
  dashboardHeader(title = "Attrition Insights with LLM"),
  dashboardSidebar(
    selectInput("employee", "Select Employee ID:", choices = 1:nrow(test)),
    actionButton("explain", "Explain Prediction")
  ),
  dashboardBody(
    verbatimTextOutput("prediction"),
    verbatimTextOutput("llm_explanation")
  )
) 
