install.packages(c("rvest", "httr", "stringr", "dplyr"))

library(rvest)
library(httr)
library(stringr)
library(tm)
library(wordcloud2)
library(htmltools)
library(htmlwidgets)

urls <- c(
  "https://www.azlyrics.com/lyrics/creed/onelastbreath.html",
  "https://www.azlyrics.com/lyrics/franksinatra/myway.html",
  "https://www.azlyrics.com/lyrics/lisa14627/dream.html",
  "https://www.azlyrics.com/lyrics/yungkai/blue.html",
  "https://www.azlyrics.com/lyrics/cranberries/zombie.html"
)

output_dir <- "lyrics_folder"
if(!dir.exists(output_dir)) {
  dir.create(output_dir)
  cat("Created folder:", output_dir, "\n")
}

# 1. Loop through each URL
for (url in urls) {
  Sys.sleep(1)
  cat("Scraping:", url, "...\n")
  
  # 2. Use httr::GET with a User-Agent to mimic a real web browser
  response <- GET(
    url, 
    add_headers(`User-Agent` = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36")
  )
  
  # 3. Read lyrics from selector gadget div
  page <- read_html(response)
  divs <- page %>% html_nodes("div:not([class]):not([id])")
  text_blocks <- divs %>% html_text() %>% trimws()
  lyrics <- text_blocks[which.max(nchar(text_blocks))]
  lyrics_lines <- strsplit(lyrics, "\n")[[1]]
  lyrics_lines <- lyrics_lines[trimws(lyrics_lines) != ""]
  lyrics_df <- data.frame(
    Lyrics = lyrics_lines, 
    stringsAsFactors = FALSE
  )

  # 4. Generate a filename dynamically and save in a folder
  url_parts <- str_split(url, "/")[[1]]
  song_part <- str_replace(url_parts[length(url_parts)], "\\.html", "")
  artist_part <- url_parts[length(url_parts)-1]
  file_name <- paste0(artist_part, "_", song_part, ".csv")
  file_path <- file.path(output_dir, file_name)
  write.csv(lyrics_df, file = file_path, row.names = FALSE)
  cat("Successfully saved to:", file_path, "\n\n")
}

cat("All scraping complete!\n")



# ==============================================================================
# PART 2: TEXT CLEANING (NLP via tm package)
# ==============================================================================
cat("Starting text cleanup...\n")

csv_files <- list.files(output_dir, pattern = "*.csv", full.names = TRUE)
all_word_counts <- data.frame()

# Custom function to replace specific patterns with a space
toSpace <- content_transformer(function(x, pattern){ gsub(pattern, " ", x) })

for (file in csv_files) {
  # Get a clean song name for the label
  song_name <- tools::file_path_sans_ext(basename(file))
  
  # Read the CSV
  df <- read.csv(file, stringsAsFactors = FALSE)
  full_text <- paste(df$Lyrics, collapse = " ")
  
  # Build and clean the Corpus
  mycorpus <- VCorpus(VectorSource(full_text))
  
  docs_1 <- tm_map(mycorpus, toSpace, "-") 
  docs_1 <- tm_map(docs_1, removePunctuation)
  docs_1 <- tm_map(docs_1, content_transformer(tolower))
  docs_1 <- tm_map(docs_1, removeNumbers)
  docs_1 <- tm_map(docs_1, removeWords, stopwords("english"))
  docs_1 <- tm_map(docs_1, stripWhitespace)
  
  # Convert to Term Document Matrix
  dtm <- TermDocumentMatrix(docs_1)
  m <- as.matrix(dtm)
  
  # Calculate frequencies and sort
  v <- sort(rowSums(m), decreasing=TRUE)
  
  # Create a dataframe for this specific song
  d <- data.frame(word = names(v), freq = as.numeric(v), song = song_name, stringsAsFactors = FALSE)
  
  # Add to our master list
  all_word_counts <- rbind(all_word_counts, d)
}

cat("Text cleanup complete!\n")


# ==============================================================================
# PART 3: GENERATE HTML WITH IFRAMES (Pandoc-Free Fix)
# ==============================================================================
cat("Generating HTML files...\n")

songs <- unique(all_word_counts$song)

# Create an empty list to hold our HTML elements
my_html_page <- list()

# Add a main title to the top of the page
my_html_page[[1]] <- tags$h1("Song Lyrics Word Clouds", style="font-family: Arial; text-align: center; color: #333; margin-bottom: 40px;")

# Loop through each song to create a cloud and a title
for (s in songs) {
  
  # Filter data for just this song
  d <- subset(all_word_counts, song == s)
  wc_data <- d[d$freq > 0, c("word", "freq")]
  
  # 1. Generate the wordcloud2 widget
  my_cloud <- wordcloud2(wc_data, size = 0.5, color = "random-dark")
  
  # 2. Save it as a standalone mini-HTML file 
  # (selfcontained = FALSE is critical here so it doesn't ask you for Pandoc!)
  cloud_filename <- paste0("cloud_", s, ".html")
  saveWidget(my_cloud, cloud_filename, selfcontained = FALSE)
  
  # 3. Add a Header for the song to our main page
  my_html_page[[length(my_html_page) + 1]] <- tags$h2(s, style="color: #2c3e50; font-family: Arial; margin-top: 50px; border-bottom: 2px solid #eee; padding-bottom: 10px;")
  
  # 4. Add an IFRAME to embed the mini-HTML file into the main page safely
  my_html_page[[length(my_html_page) + 1]] <- tags$iframe(
    src = cloud_filename,
    width = "100%",
    height = "550px",
    style = "border: none; overflow: hidden;"
  )
}

# 5. Save the main index.html file!
save_html(tagList(my_html_page), file = "index.html")

cat("SUCCESS! Your 'index.html' has been created. Open it to view all your word clouds!\n")