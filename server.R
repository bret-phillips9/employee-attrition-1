server <- function(input, output, session) {
  selected_employee <- reactive({
    test[which(test$EmployeeNumber == input$employee), ]
  })
  
  selected_job <- reactive({
    selected_employee()$Job
  })
  
  employee_benchmarks <- reactive({
    req(selected_employee())
    benchmarks[which(benchmarks$Job == selected_employee()$Job), ] 
  })
  
  output$emp_head <- renderText({
    req(selected_employee())
    paste0("Data for Employee #", input$employee)
  })
  
  output$pred_head <- renderText({
    req(selected_employee())
    paste0("Predictions for Employee #", input$employee)
  })
  
  output$emp_tbl <- renderDT({
    req(selected_employee())
    emp_long <- selected_employee() |> 
      mutate(across(everything(), as.character)) |> 
      pivot_longer(cols = everything(), names_to = "Attribute", values_to = "Value")
    print(emp_long)
  })
  
  flight_prob <- reactive({
    req(selected_employee())
    emp <- selected_employee()
    rf_pred <- predict(rf_fit, emp, type = "prob")
  })
  
  output$prediction <- renderText({
    req(flight_prob())
    paste0("Probability of Attrition: ", round(flight_prob()[2] * 100, 2), "%")
  })

  observeEvent(input$explain, {
    # Set GPT model
    gpt_model = "gpt-4.1-nano"
    
    showModal(modalDialog(paste("Waiting for", gpt_model, "..."), footer=NULL))
    on.exit(removeModal())
    
    emp <- selected_employee()
    input_data <- emp |> select(-Attrition, -EmployeeNumber, -attrit_pred)
    context <- paste("You are an HR analytics expert. A random forest classifier shows that the employee characteristics related to attrition are, from most to least important: ", vars_by_imp)
    context <- paste(context, "You are evaluating the attrition risk of an employee in job role", selected_job())
    context <- paste(context, "Average values of selected pay-related factors for employees in this job role are:", toJSON(employee_benchmarks(), auto_unbox = TRUE))
    prompt <- "Using the information on feature importance and average values"
    prompt <- paste(prompt, "explain why an employee with the following characteristics has a", round(flight_prob()[2] * 100, 2), "percent chance of leaving:", toJSON(input_data, auto_unbox = TRUE))
    prompt <- paste(prompt, "Then, if the employee has a moderate to high risk of leaving, suggest the likeliest intervention(s) that would result in retaining this employee.")
    
    # Call OpenAI 
    # NOTE: for this app to work, an environment variable named OPENAI_API_KEY
    # containing your secret OpenAI API key must be set 
    # for security, your key must be passed to the environment before the app runs
    # e.g., Sys.setenv(OPENAI_API_KEY = "sk-proj-123456789")
    # NOTE #2: This code invokes gpt-4.1-nano for cost savings, you may wish to specify
    # a different gpt model below in the "model =" line
    llm_resp <- POST("https://api.openai.com/v1/chat/completions",
                add_headers(Authorization = paste("Bearer", Sys.getenv("OPENAI_API_KEY"))),
                content_type_json(),
                body = list(
                  model = gpt_model,
                  messages = list(
                    list(role = "system", content = context),
                    list(role = "user", content = prompt)
                  )
                ), encode = "json")

    if (llm_resp$status_code == 200) {
      explanation <- content(llm_resp)$choices[[1]]$message$content
    } else {
      explanation <- paste("HTTP error", llm_resp$status_code)
    }
    output$llm_explanation <- renderUI(markdown(explanation))
  })
  
  output$confusion_matrix <- renderPrint(confusionMatrix(cm_tbl))
  
  output$var_importance <- renderPlot(varImpPlot(rf_fit))
}
