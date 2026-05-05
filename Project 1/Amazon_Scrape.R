install.packages("openxlsx")

library(rvest)
library(httr)
library(tidyverse)
library(openxlsx)
library(curl)

# Define the search URL for the first product category (Smart Garage Relays)
base_url <- "https://www.amazon.com.au/s?k=smart+garage+relay&page="
pages <- paste0(base_url, 1:3)

# Define the search URL for the second product category (Smart Hub)
urls_hub <- c(
  paste0("https://www.amazon.com.au/s?k=zigbee+hub&page=", 1:3),
  "https://www.amazon.com.au/s?k=matter+hub&page=1",
  "https://www.amazon.com.au/s?k=matter+gateway&page=1",
  paste0("https://www.amazon.com.au/s?k=smart+home+hub&page=", 1:3),
  paste0("https://www.amazon.com.au/s?k=smart+gateway&page=", 1:3)
)

u_agent <- "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36"

scrape_amazon_page <- function(url) {
  message(paste("Scraping:", url))
  Sys.sleep(runif(1, 3, 6)) 
  
  res <- GET(url, add_headers(`User-Agent` = u_agent))
  webpage <- read_html(res)
  
  # Focus on the specific search result containers to avoid 'Previous page' noise
  products <- webpage %>% html_nodes("div.s-result-item[data-component-type='s-search-result']")
  
  # Function to safely grab data
  safe_get <- function(node, selector) {
    val <- node %>% html_node(selector) %>% html_text(trim = TRUE)
    return(if(length(val) == 0) NA else val)
  }
  
  # Build data frame for the page
  page_df <- data.frame(
    Title = sapply(products, function(x) safe_get(x, ".a-text-normal")),

    Price = sapply(products, function(x) safe_get(x, ".a-price .a-offscreen")),
    Price2 = sapply(products, function(x) safe_get(x, "div span")),



    Stars = sapply(products, function(x) safe_get(x, "span.a-icon-alt")),
    Num_Reviews = sapply(products, function(x) safe_get(x, ".a-size-small")),
    Image_URL = sapply(products, function(x) x %>% html_node(".s-image") %>% html_attr("src")),
    stringsAsFactors = FALSE
  )
  return(page_df)
}

# Re-run the scrape
all_data <- map_df(pages, scrape_amazon_page)

raw_hub_data <- urls_hub %>% 
  map_df(~scrape_amazon_page(.x))


print(paste("Total items scraped:", nrow(raw_hub_data)))

# --- CLEANING THE DATA ---
final_dataset <- all_data %>%
  filter(!is.na(Title)) %>% 
  mutate(
    # 1. Clean the primary Price first (Standard numeric conversion)
    Price_Primary = as.numeric(gsub("[^0-9.]", "", Price)),
    
    # 2. Extract the price from the messy Price2 string ($185.00)
    # We use str_extract with a regex for $ followed by digits and decimals
    Price_Fallback = str_extract(Price2, "\\$[0-9,]+\\.[0-9]{2}"),
    Price_Fallback = as.numeric(gsub("[^0-9.]", "", Price_Fallback)),
    
    # 3. Combine them: If Price_Primary is NA, use Price_Fallback
    Price = ifelse(is.na(Price_Primary), Price_Fallback, Price_Primary),
    
    # 4. Clean Stars and Reviews
    Stars = as.numeric(str_extract(Stars, "^[0-9.]+")),

    #Num_Reviews = as.numeric(gsub("[^0-9]", "", Num_Reviews))
    Num_Reviews = sapply(Num_Reviews, function(x) {
    	if (is.na(x)) return(NA)
    
    	# 1. Extract just the content inside the parentheses (e.g., "3.7K" or "812")
    	count_str <- str_extract(x, "(?<=\\()[^\\)]+(?=\\))")
    
    	if (is.na(count_str)) return(NA)
    
    	# 2. Check if it contains 'K'. If so, multiply by 1000
    	if (grepl("K", count_str)) {
      	  num <- as.numeric(gsub("[^0-9.]", "", count_str)) * 1000
    	} else {
      	  num <- as.numeric(gsub("[^0-9.]", "", count_str))
    	}
    	return(num)
    })

  ) %>%
  # Remove the temporary helper columns so only the final 'Price' remains
  select(-Price_Primary, -Price_Fallback, -Price2) %>%
  # Sort by number of reviews
  arrange(desc(Num_Reviews))

str(raw_hub_data)

clean_hub_data <- raw_hub_data %>%
  filter(!is.na(Title)) %>% 

  # --- THE "ANYTHING CONTAINS" FILTER ---
  filter(!str_detect(tolower(Title), "switch|socket|camera|lock|usb hub|harmony hub|guide|irrigation|usb4 hub|monitor|keypad|yale|physics|muggles
	|riser|bulb|led strip|sensor|light|thermostat|doorbell|highlander|no hub|hub required|watering kit|sticker|mate
	|require zigbee hub|adapter|compatible with gateway|sprinker|water|door|notebook|matter's end|keybox|geometric|hella")) %>%

  mutate(
    # 1. Price Cleaning (Primary vs Fallback)
    Price_Primary = as.numeric(gsub("[^0-9.]", "", Price)),
    Price_Fallback = str_extract(Price2, "\\$[0-9,]+\\.[0-9]{2}"),
    Price_Fallback = as.numeric(gsub("[^0-9.]", "", Price_Fallback)),
    Price = ifelse(is.na(Price_Primary), Price_Fallback, Price_Primary),
    
    # 2. Stars Cleaning
    Stars = as.numeric(str_extract(Stars, "^[0-9.]+")),

    # 3. Num_Reviews Cleaning (with Parentheses and 'K' logic)
    Num_Reviews = sapply(Num_Reviews, function(x) {
        if (is.na(x)) return(NA)
        count_str <- str_extract(x, "(?<=\\()[^\\)]+(?=\\))")
        if (is.na(count_str)) return(NA)
        
        if (grepl("K", count_str)) {
            return(as.numeric(gsub("[^0-9.]", "", count_str)) * 1000)
        } else {
            return(as.numeric(gsub("[^0-9.]", "", count_str)))
        }
    })
  ) %>%
  # 4. Final Organization
  select(-Price_Primary, -Price_Fallback, -Price2) %>%
  distinct(Price, Stars, Num_Reviews, .keep_all = TRUE) %>% 
  arrange(desc(Num_Reviews))

print(head(final_dataset, 10))
#----------------------------------------------
#--------- EXPORT to CSV and to XLSX ----------
#-----------------------------------------------

export_amazon_to_xlsx <- function(data, filename) {
  
  # 1. Basic CSV Export (Always good for a quick backup)
  csv_name <- gsub(".xlsx", ".csv", filename)
  write.csv(data, csv_name, row.names = FALSE)
  message(paste("CSV saved:", csv_name))
  
  # 2. XLSX Setup
  wb <- createWorkbook()
  addWorksheet(wb, "Amazon Products")
  writeData(wb, "Amazon Products", data)
  
  # Set dimensions: rows 2 to N+1
  setRowHeights(wb, "Amazon Products", rows = 2:(nrow(data) + 1), heights = 100)
  # Assuming Image_URL is in column 5
  setColWidths(wb, "Amazon Products", cols = 5, widths = 25)
  
  # 3. Image Embedding Loop
  num_to_embed <- nrow(data)
  message(paste("Processing", filename, "-", num_to_embed, "images..."))
  
  for (i in 1:num_to_embed) {
    img_url <- data$Image_URL[i]
    
    if (!is.na(img_url) && img_url != "") {
      tmp_file <- tempfile(fileext = ".jpg")
      
      try({
        curl_download(img_url, tmp_file)
        
        insertImage(wb, "Amazon Products", tmp_file, 
                    startRow = i + 1, startCol = 5, 
                    width = 1.8, height = 1.3, units = "in")
        
        # Pause to prevent server blocking
        Sys.sleep(0.2) 
      }, silent = TRUE)
    }
  }
  
  # 4. Save
  saveWorkbook(wb, filename, overwrite = TRUE)
  message(paste("Success! File ready:", filename))
}

# Export the first category (Smart Garage)
export_amazon_to_xlsx(final_dataset, "Amazon_Smart_Garage.xlsx")
# Export the second category (Smart Hubs)
export_amazon_to_xlsx(clean_hub_data, "Amazon_Smart_Hubs.xlsx")

#-----------------------------------------------------
#---------Shiny dashboard to show bubble plot---------
#-----------------------------------------------------
library(shiny)
library(plotly)
library(dplyr)
library(stringr)

# --- UI Side ---
ui <- fluidPage(
  titlePanel("Amazon Smart Garage Relay Analysis"),
  sidebarLayout(
    sidebarPanel(
      width = 3,
      h3("Product Inspector"),
      hr(),
      uiOutput("product_image"),
      hr(),
      uiOutput("product_details")
    ),
    mainPanel(
      width = 9,
      plotlyOutput("bubblePlot", height = "600px")
    )
  )
)

# --- Server Side ---
server <- function(input, output, session) {
  
  # 1. Initialize "Memory" for the last hovered product
  # This starts as NULL and only changes when you touch a bubble
  last_hovered <- reactiveVal(NULL)
  
  # 2. Update the Memory when a hover event happens
  observeEvent(event_data("plotly_hover"), {
    d <- event_data("plotly_hover")
    if (!is.null(d)) {
      # Identify the specific product using the key (Title)
      prod_info <- final_dataset %>% filter(Title == d$key) %>% slice(1)
      last_hovered(prod_info) # Store it in memory
    }
  })

  # 3. Render the Plotly Bubble Chart
  output$bubblePlot <- renderPlotly({
    # Calculate the max price to set ticks dynamically
    max_p <- max(final_dataset$Price, na.rm = TRUE)
    
    plot_ly(
      data = final_dataset,
      x = ~Price,
      y = ~Stars,
      size = ~Num_Reviews,
      # Color Scale: Red (Low) -> Yellow (Mid) -> Green (High)
      color = ~Stars,
      colors = c("#FF0000", "#FFFF00", "#00FF00"), 
      type = 'scatter',
      mode = 'markers',
      key = ~Title, 
      marker = list(sizemode = 'diameter', opacity = 0.6, sizes = c(10, 50)),
      hoverinfo = 'text',
      text = ~paste("Product:", str_trunc(Title, 40), "<br>Price: $", Price)
    ) %>%
      layout(
        xaxis = list(
          title = "Price ($)",
          dtick = 25,     # <--- X Ticks every $25
          tick0 = 0,
          gridcolor = "#f0f0f0"
        ),
        yaxis = list(title = "Star Rating", gridcolor = "#f0f0f0"),
        hovermode = "closest"
      )
  })
  
  # 4. Render Image (Uses the "Memory" reactiveVal)
  output$product_image <- renderUI({
    prod <- last_hovered()
    if (is.null(prod)) {
      return(helpText("Hover over a bubble to inspect a product"))
    }
    tags$img(src = prod$Image_URL, width = "100%", 
             style = "border: 1px solid #ddd; border-radius: 5px; box-shadow: 2px 2px 5px #ccc;")
  })
  
  # 5. Render Details (Uses the "Memory" reactiveVal)
  output$product_details <- renderUI({
    prod <- last_hovered()
    if (is.null(prod)) return(NULL)
    
    tagList(
      h4(prod$Title),
      p(strong("Price: "), paste0("$", format(prod$Price, nsmall = 2))),
      p(strong("Rating: "), paste(prod$Stars, "/ 5.0")),
      p(strong("Reviews: "), format(prod$Num_Reviews, big.mark = ","))
    )
  })
}

shinyApp(ui, server)


library(shiny)
library(plotly)
library(dplyr)
library(stringr)
library(ggplot2)

# --- UI Side ---
ui <- fluidPage(
  titlePanel("Amazon Smart Home Analysis: Relays vs Hubs"),
  
  tabsetPanel(
    # TAB 1: Garage Relays
    tabPanel("Garage Relays",
             sidebarLayout(
               sidebarPanel(
                 width = 3,
                 h3("Relay Inspector"),
                 uiOutput("relay_image"),
                 hr(),
                 uiOutput("relay_details")
               ),
               mainPanel(
                 width = 9,
                 plotlyOutput("relayPlot", height = "600px")
               )
             )
    ),
    
    # TAB 2: Smart Hubs
    tabPanel("Smart Hubs",
             sidebarLayout(
               sidebarPanel(
                 width = 3,
                 h3("Hub Inspector"),
                 uiOutput("hub_image"),
                 hr(),
                 uiOutput("hub_details")
               ),
               mainPanel(
                 width = 9,
                 plotlyOutput("hubPlot", height = "600px")
               )
             )
    ),
    
    # TAB 3: Comparative Analysis
    tabPanel("Market Comparison",
             mainPanel(
               width = 12,
               h3("Distribution Comparison: Relays vs Hubs"),
               p("Dashed lines represent the Mean (Average) for each category."),
               fluidRow(
                 column(4, plotOutput("histPrice")),
                 column(4, plotOutput("histStars")),
                 column(4, plotOutput("histReviews"))
               )
             )
    )
  )
)

# --- Server Side ---
server <- function(input, output, session) {
  
  # --- Logic for Tab 1 (Relays) ---
  last_hovered_relay <- reactiveVal(NULL)
  observeEvent(event_data("plotly_hover", source = "relay"), {
    d <- event_data("plotly_hover", source = "relay")
    if (!is.null(d)) {
      prod_info <- final_dataset %>% filter(Title == d$key) %>% slice(1)
      last_hovered_relay(prod_info)
    }
  })
  
  output$relayPlot <- renderPlotly({
    plot_ly(data = final_dataset, x = ~Price, y = ~Stars, size = ~Num_Reviews,
            color = ~Stars, colors = c("#FF0000", "#FFFF00", "#00FF00"),
            type = 'scatter', mode = 'markers', key = ~Title, source = "relay",
            marker = list(sizemode = 'diameter', opacity = 0.6, sizes = c(10, 50)),
            text = ~paste("Product:", str_trunc(Title, 40), "<br>Price: $", Price)) %>%
      layout(xaxis = list(title = "Price ($)", dtick = 25), yaxis = list(title = "Star Rating"), hovermode = "closest")
  })
  
  output$relay_image <- renderUI({
    prod <- last_hovered_relay()
    if (is.null(prod)) return(helpText("Hover over a bubble"))
    tags$img(src = prod$Image_URL, width = "100%", style = "border-radius: 5px; border: 1px solid #ddd;")
  })
  
  output$relay_details <- renderUI({
    prod <- last_hovered_relay()
    if (is.null(prod)) return(NULL)
    tagList(h4(prod$Title), p(strong("Price: "), paste0("$", prod$Price)), p(strong("Rating: "), prod$Stars))
  })

  # --- Logic for Tab 2 (Hubs) ---
  last_hovered_hub <- reactiveVal(NULL)
  observeEvent(event_data("plotly_hover", source = "hub"), {
    d <- event_data("plotly_hover", source = "hub")
    if (!is.null(d)) {
      prod_info <- clean_hub_data %>% filter(Title == d$key) %>% slice(1)
      last_hovered_hub(prod_info)
    }
  })
  
  output$hubPlot <- renderPlotly({
    plot_ly(data = clean_hub_data, x = ~Price, y = ~Stars, size = ~Num_Reviews,
            color = ~Stars, colors = c("#FF0000", "#FFFF00", "#00FF00"),
            type = 'scatter', mode = 'markers', key = ~Title, source = "hub",
            marker = list(sizemode = 'diameter', opacity = 0.6, sizes = c(10, 50)),
            text = ~paste("Product:", str_trunc(Title, 40), "<br>Price: $", Price)) %>%
      layout(xaxis = list(title = "Price ($)", dtick = 50), yaxis = list(title = "Star Rating"), hovermode = "closest")
  })
  
  output$hub_image <- renderUI({
    prod <- last_hovered_hub()
    if (is.null(prod)) return(helpText("Hover over a bubble"))
    tags$img(src = prod$Image_URL, width = "100%", style = "border-radius: 5px; border: 1px solid #ddd;")
  })
  
  output$hub_details <- renderUI({
    prod <- last_hovered_hub()
    if (is.null(prod)) return(NULL)
    tagList(h4(prod$Title), p(strong("Price: "), paste0("$", prod$Price)), p(strong("Rating: "), prod$Stars))
  })

  # --- Logic for Tab 3 (Comparison) ---
  
  # Create a combined dataset for ggplot
  combined_data <- bind_rows(
    final_dataset %>% mutate(Category = "Relay"),
    clean_hub_data %>% mutate(Category = "Hub")
  )

  # Helper function to create histograms with Mean/SD
  create_comp_hist <- function(df, col_name, title) {
    # Calculate stats
    stats <- df %>% group_by(Category) %>% 
      summarise(mean_val = mean(!!sym(col_name), na.rm=T), sd_val = sd(!!sym(col_name), na.rm=T))
    
    ggplot(df, aes_string(x = col_name, fill = "Category")) +
      geom_histogram(alpha = 0.6, position = "identity", bins = 20) +
      geom_vline(data = stats, aes(xintercept = mean_val, color = Category), linetype = "dashed", size = 1) +
      labs(title = title, subtitle = paste0("SD (Relay): ", round(stats$sd_val[2], 1), 
                                           " | SD (Hub): ", round(stats$sd_val[1], 1))) +
      theme_minimal() + theme(legend.position = "top")
  }

  output$histPrice <- renderPlot({ create_comp_hist(combined_data, "Price", "Price Comparison") })
  output$histStars <- renderPlot({ create_comp_hist(combined_data, "Stars", "Star Rating Comparison") })
  output$histReviews <- renderPlot({ create_comp_hist(combined_data, "Num_Reviews", "Review Count Comparison") })
}

shinyApp(ui, server)


library(shiny)
library(plotly)
library(dplyr)
library(stringr)
library(ggplot2)

# --- UI Side ---
ui <- fluidPage(
  titlePanel("Amazon Smart Home Analysis: Relays vs Hubs"),
  
  tabsetPanel(
    # TAB 1: Garage Relays
    tabPanel("Garage Relays",
             sidebarLayout(
               sidebarPanel(
                 width = 3,
                 h3("Relay Inspector"),
                 uiOutput("relay_image"),
                 hr(),
                 uiOutput("relay_details")
               ),
               mainPanel(
                 width = 9,
                 plotlyOutput("relayPlot", height = "600px")
               )
             )
    ),
    
    # TAB 2: Smart Hubs
    tabPanel("Smart Hubs", 
             sidebarLayout(
               sidebarPanel(
                 width = 3,
                 h3("Hub Inspector"),
                 uiOutput("hub_image"),
                 hr(),
                 uiOutput("hub_details")
               ),
               mainPanel(
                 width = 9,
                 plotlyOutput("hubPlot", height = "600px")
               )
             )
    ),
    
    # TAB 3: Comparative Analysis
    tabPanel("Market Comparison",
             mainPanel(
               width = 10, # Centered layout
               offset = 1,
               h3("Distribution Comparison: Relays vs Hubs"),
               p("Dashed lines represent the Mean. Curves represent the distribution density."),
               plotOutput("histPrice", height = "400px"),
               plotOutput("histStars", height = "400px"),
               plotOutput("histReviews", height = "400px")
             )
    )
  )
)

# --- Server Side ---
server <- function(input, output, session) {
  
  # --- Common Hover Label Function ---
  # Re-adding Num_Reviews to the hover text logic
  
  # --- Logic for Tab 1 (Relays) ---
  last_hovered_relay <- reactiveVal(NULL)
  observeEvent(event_data("plotly_hover", source = "relay"), {
    d <- event_data("plotly_hover", source = "relay")
    if (!is.null(d)) {
      prod_info <- final_dataset %>% filter(Title == d$key) %>% slice(1)
      last_hovered_relay(prod_info)
    }
  })
  
  output$relayPlot <- renderPlotly({
    plot_ly(data = final_dataset, x = ~Price, y = ~Stars, size = ~Num_Reviews,
            color = ~Stars, colors = c("#FF0000", "#FFFF00", "#00FF00"),
            type = 'scatter', mode = 'markers', key = ~Title, source = "relay",
            marker = list(sizemode = 'diameter', opacity = 0.6, sizes = c(10, 50)),
            # ADDED Num_Reviews to Hover Text
            text = ~paste("Product:", str_trunc(Title, 40), 
                          "<br>Price: $", Price,
                          "<br>Reviews:", format(Num_Reviews, big.mark=","))) %>%
      layout(xaxis = list(title = "Price ($)", dtick = 25), yaxis = list(title = "Star Rating"), hovermode = "closest")
  })
  
  output$relay_image <- renderUI({
    prod <- last_hovered_relay()
    if (is.null(prod)) return(helpText("Hover over a bubble"))
    tags$img(src = prod$Image_URL, width = "100%", style = "border-radius: 5px; border: 1px solid #ddd;")
  })
  
  output$relay_details <- renderUI({
    prod <- last_hovered_relay()
    if (is.null(prod)) return(NULL)
    tagList(
      h4(prod$Title), 
      p(strong("Price: "), paste0("$", format(prod$Price, nsmall=2))), 
      p(strong("Rating: "), prod$Stars),
      p(strong("Reviews: "), format(prod$Num_Reviews, big.mark=",")) # ADDED to Side Panel
    )
  })

  # --- Logic for Tab 2 (Hubs) ---
  last_hovered_hub <- reactiveVal(NULL)
  observeEvent(event_data("plotly_hover", source = "hub"), {
    d <- event_data("plotly_hover", source = "hub")
    if (!is.null(d)) {
      prod_info <- clean_hub_data %>% filter(Title == d$key) %>% slice(1)
      last_hovered_hub(prod_info)
    }
  })
  
  output$hubPlot <- renderPlotly({
    plot_ly(data = clean_hub_data, x = ~Price, y = ~Stars, size = ~Num_Reviews,
            color = ~Stars, colors = c("#FF0000", "#FFFF00", "#00FF00"),
            type = 'scatter', mode = 'markers', key = ~Title, source = "hub",
            marker = list(sizemode = 'diameter', opacity = 0.6, sizes = c(10, 50)),
            # ADDED Num_Reviews to Hover Text
            text = ~paste("Product:", str_trunc(Title, 40), 
                          "<br>Price: $", Price,
                          "<br>Reviews:", format(Num_Reviews, big.mark=","))) %>%
      layout(xaxis = list(title = "Price ($)", dtick = 50), yaxis = list(title = "Star Rating"), hovermode = "closest")
  })
  
  output$hub_image <- renderUI({
    prod <- last_hovered_hub()
    if (is.null(prod)) return(helpText("Hover over a bubble"))
    tags$img(src = prod$Image_URL, width = "100%", style = "border-radius: 5px; border: 1px solid #ddd;")
  })
  
  output$hub_details <- renderUI({
    prod <- last_hovered_hub()
    if (is.null(prod)) return(NULL)
    tagList(
      h4(prod$Title), 
      p(strong("Price: "), paste0("$", format(prod$Price, nsmall=2))), 
      p(strong("Rating: "), prod$Stars),
      p(strong("Reviews: "), format(prod$Num_Reviews, big.mark=",")) # ADDED to Side Panel
    )
  })

  # --- Logic for Tab 3 (Comparison) ---
  combined_data <- bind_rows(
    final_dataset %>% mutate(Category = "Relay"),
    clean_hub_data %>% mutate(Category = "Hub")
  )

  create_comp_hist <- function(df, col_name, title) {
    stats <- df %>% group_by(Category) %>% 
      summarise(mean_val = mean(!!sym(col_name), na.rm=T))
  
    ggplot(df, aes_string(x = col_name, fill = "Category")) +
      # 1. Keep the bars filled (alpha controls transparency)
      geom_histogram(aes(y = ..density..), alpha = 0.4, position = "identity", bins = 30) +
    
      # 2. UPDATED: Smooth Normal Curve as a line only (fill = NA)
      geom_density(aes(color = Category), fill = NA, size = 1) +
    
      # 3. Mean Line
      geom_vline(data = stats, aes(xintercept = mean_val, color = Category), linetype = "dashed", size = 1) +
    
      # 4. Text label for the mean
      geom_text(data = stats, aes(x = mean_val, y = Inf, label = paste("Mean:", round(mean_val, 1)), color = Category), 
              vjust = 1.5, hjust = -0.1, fontface = "bold", show.legend = FALSE) +
    
      labs(title = title, x = title, y = "Density") +
      theme_minimal() + 
      theme(legend.position = "right")
  }

  output$histPrice <- renderPlot({ create_comp_hist(combined_data, "Price", "Price ($)") })
  output$histStars <- renderPlot({ create_comp_hist(combined_data, "Stars", "Star Rating") })
  output$histReviews <- renderPlot({ create_comp_hist(combined_data, "Num_Reviews", "Number of Reviews") })
}

shinyApp(ui, server)





