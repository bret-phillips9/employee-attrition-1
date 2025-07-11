server <- function(input, output, session) {
  selected_employee <- reactive({
    test[input$employee, ]
  })

  output$prediction <- renderPrint({
    emp <- selected_employee()
    rf_pred <- predict(rf_fit, emp, type = "prob")
    paste0("Probability of Attrition: ", round(rf_pred[2] * 100, 2), "%")
  })

  observeEvent(input$explain, {
    emp <- selected_employee()
    input_data <- emp |> select(Age, JobSatisfaction, MonthlyIncome, OverTime, TotalWorkingYears, YearsAtCompany)
    prompt <- paste("Explain why this employee might leave:", toJSON(input_data, auto_unbox = TRUE))

    # Call OpenAI 
    # NOTE: for this app to work, an environment variable named OPENAI_API_KEY
    # containing your secret OpenAI API key must be set 
    # for security, your key must be passed to the environment before the app runs
    # e.g., Sys.setenv(OPENAI_API_KEY = "sk-proj-123456789")
    # NOTE #2: This code invokes gpt-4.1-nano for cost savings, you may wish to specify
    # a different gpt model below
    llm_resp <- POST("https://api.openai.com/v1/chat/completions",
                add_headers(Authorization = paste("Bearer", Sys.getenv("OPENAI_API_KEY"))),
                content_type_json(),
                body = list(
                  model = "gpt-4.1-nano",
                  messages = list(
                    list(role = "system", content = "You are an HR analytics expert."),
                    list(role = "user", content = prompt)
                  )
                ), encode = "json")

    if (llm_resp$status_code == 200) {
      explanation <- content(llm_resp)$choices[[1]]$message$content
    } else {
      explanation <- paste("HTTP error", llm_resp$status_code)
    }
    output$llm_explanation <- renderText(explanation)
  })
}
