# ==============================================================================
# ASSIGNMENT TASK 3: SENTIMENT ANALYSIS
# Name: Muzaffar Izamuddin | Course Code: STQD6114
# Data Sources: 
#   - https://www.productreview.com.au/listings/polyaire-airtouch-4
#   - https://www.productreview.com.au/listings/polyaire-airtouch-5
# ==============================================================================

# 1. INITIAL SETUP AND LIBRARY LOADING
# Install missing libraries if necessary
install.packages("rvest")
install.packages("httr")
install.packages("syuzhet")
install.packages("ggplot2")
install.packages("tidytext")
install.packages("dplyr")
install.packages("stringr")
install.packages("tm")

library(rvest)
library(httr)
library(syuzhet)
library(ggplot2)
library(tidytext)
library(dplyr)
library(stringr)
library(tm)

# ==============================================================================
# PART 1: DATA ACQUISITION & SCRAPING $ CLEANING
# ==============================================================================

urls <- c(
  "https://www.productreview.com.au/listings/polyaire-airtouch-4",
  "https://www.productreview.com.au/listings/polyaire-airtouch-5"
)

scraped_text <- c()

# Loop through each URL and attempt scraping using user-agent spoofing
for (url in urls) {
  message("Attempting to crawl data from: ", url)
  
  tryCatch({
    # Add a realistic User-Agent browser string to try bypassing security blocks
    response <- GET(url, add_headers(`User-Agent` = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"))
    
    if (status_code(response) == 200) {
      page_html <- read_html(response)
      # Extract text using your provided SelectorGadget target element class
      reviews <- page_html %>% html_nodes(".hBRYlm") %>% html_text(trim = TRUE)
      
      if(length(reviews) > 0) {
        scraped_text <- c(scraped_text, reviews)
        message("Successfully scraped ", length(reviews), " reviews.")
      } else {
        message("Page loaded, but no nodes matched '.hBRYlm'. Cloudflare JS challenge likely active.")
      }
    } else {
      message("HTTP Error code received: ", status_code(response))
    }
  }, error = function(e) {
    message("Could not access page directly due to: ", e$message)
  })
}

# ==============================================================================
#    Save metadata and seperate from main review text
# ==============================================================================
library(stringr)
library(dplyr)

#initial cleaning
scraped_text_clean_spaces <- str_replace_all(scraped_text, "[\u2002\u00a0\\s]+", " ")

# Initialize vectors to collect extracted components safely
author_name_vec <- character(length(scraped_text_clean_spaces))
state_vec       <- character(length(scraped_text_clean_spaces))
post_count_vec  <- character(length(scraped_text_clean_spaces))
recency_vec     <- character(length(scraped_text_clean_spaces))
review_text_vec <- character(length(scraped_text_clean_spaces))
verified_vec    <- character(length(scraped_text_clean_spaces)) 

# 2. Process every row by splitting cleanly at the 'Vote' anchor point
for (i in 1:length(scraped_text_clean_spaces)) {
  current_line <- scraped_text_clean_spaces[i]
  
  # Locate where the text "Vote" or "Vote (" starts
  vote_pos <- str_locate(current_line, "Vote(\\s*\\(\\d+\\))?More")
  
  if (!is.na(vote_pos[1, 1])) {
    # Cut the text into two pieces right at the Vote button boundary
    metadata_part <- str_sub(current_line, 1, vote_pos[1, 1] - 1)
    review_part   <- str_sub(current_line, vote_pos[1, 2] + 1)
    
    # --- PARSE THE METADATA PART SAFELY ---
    # A. Look for and extract "Verified" layout variation metrics first
    if (str_detect(metadata_part, "Verified")) {
      verified_vec[i] <- "Yes"
      # Find the recency indicator preceding the word Verified (e.g., "3y Verified" or "9mo Verified")
      recency_match <- str_extract(metadata_part, "\\d+\\s*(mo|y|w|d)(?=\\s*Verified)")
      if (!is.na(recency_match)) {
        recency_vec[i] <- str_trim(recency_match)
      } else {
        recency_vec[i] <- "Unknown"
      }
      # Strip the entire variant out of the string
      metadata_part <- str_replace(metadata_part, "\\d+\\s*(mo|y|w|d)\\s*Verified", "")
    } else {
      verified_vec[i] <- "No"
      # Standard case: Look for digits followed by 'mo', 'w', 'd', or 'y' right at the end
      recency_match <- str_extract(metadata_part, "\\d+\\s*(mo|y|w|d)\\s*$")
      if (!is.na(recency_match)) {
        recency_vec[i] <- str_trim(recency_match)
        metadata_part  <- str_replace(metadata_part, "\\d+\\s*(mo|y|w|d)\\s*$", "")
      } else {
        recency_vec[i] <- "Unknown"
      }
    }
    
    # B. Extract Post Counts: Look for standard "X posts" pattern anywhere remaining
    posts_match <- str_extract(metadata_part, "\\d+\\s*posts")
    if (!is.na(posts_match)) {
      post_count_vec[i] <- str_trim(posts_match)
      metadata_part     <- str_replace(metadata_part, "\\d+\\s*posts", "")
    } else {
      post_count_vec[i] <- "1 post"
    }
    
    # C. Extract State Codes: Look for standalone uppercase Australian State codes
    state_match <- str_extract(metadata_part, "\\b(VIC|NSW|QLD|WA|SA|ACT|TAS|NT)\\b")
    if (!is.na(state_match)) {
      state_vec[i]  <- str_trim(state_match)
      metadata_part <- str_replace(metadata_part, "\\b(VIC|NSW|QLD|WA|SA|ACT|TAS|NT)\\b", "")
    } else {
      state_vec[i]  <- "Not Specified"
    }
    
    # D. Author Name: Clean up remaining text to get the user name
    author_name_vec[i] <- str_trim(metadata_part)
    review_text_vec[i] <- str_trim(review_part)
    
  } else {
    # Fallback structure for anomalies
    author_name_vec[i] <- "Anonymous"
    state_vec[i]       <- "Not Specified"
    post_count_vec[i]  <- "Unknown"
    recency_vec[i]     <- "Unknown"
    review_text_vec[i] <- current_line
    verified_vec[i]    <- "No"
  }
}

# 3. Create the finalized Metadata Data Frame
metadata_df <- data.frame(
  Review_ID   = 1:length(scraped_text),
  Author_Name = author_name_vec,
  State       = state_vec,
  Post_Count  = post_count_vec,
  Recency     = recency_vec,
  Verified    = verified_vec,
  stringsAsFactors = FALSE
)

# Enforce clean presentation rules
metadata_df <- metadata_df %>%
  mutate(Author_Name = ifelse(Author_Name == "" | is.na(Author_Name), "Anonymous", Author_Name))

cat("\n--- Finalized Metadata Frame Output Check ---\n")
print(head(metadata_df, 37))

#=========save file for manual review============================================
# 1. Open a fresh file connection
file_conn <- file("unpacked_reviews_diagnostic2.txt", "w")

# 2. Loop through the elements safely. 
if (length(scraped_text_clean_spaces) == 1) {
  writeLines("DIAGNOSTIC ALERT: Your vector only contains 1 giant text string!", file_conn)
  writeLines("=========================================================", file_conn)
  writeLines(scraped_text_clean_spaces, file_conn)
} else {
  for (i in 1:length(scraped_text_clean_spaces)) {
    writeLines(paste0("========================================="), file_conn)
    writeLines(paste0("REVIEW ENTRY NUMBER: ", i), file_conn)
    writeLines(paste0("========================================="), file_conn)
    writeLines(scraped_text_clean_spaces[i], file_conn)
    writeLines("", file_conn) 
  }
}

# 3. Close the file connection safely
close(file_conn)
message("File successfully saved as 'unpacked_reviews_diagnostic2.txt'")

# ==============================================================================
#    standard text cleaning
# ==============================================================================

review_text_clean <- gsub("(?i)MoreAirTouch.*$", "", review_text_vec, perl = TRUE) #needed as review replies are also in

ui_noise <- c("Show details", "Read more", "\\(\\+\\d+ replies\\)", "· \\d+")
for (noise in ui_noise) {
  review_text_clean <- gsub(noise, "", review_text_clean, perl = TRUE)
}

mycorpus <- VCorpus(VectorSource(review_text_clean))
toSpace <- content_transformer(function(x, pattern) { gsub(pattern, " ", x) })
docs <- tm_map(mycorpus, toSpace, "–")
docs <- tm_map(docs, toSpace, ",")
docs <- tm_map(docs, toSpace, "!")
docs <- tm_map(docs, toSpace, "’")
docs <- tm_map(docs, toSpace, "‘")
docs <- tm_map(docs, toSpace, "'")
docs <- tm_map(docs, toSpace, ":") 
docs <- tm_map(docs, toSpace, "\\.") 
docs <- tm_map(docs, toSpace, "\\?") 
docs <- tm_map(docs, toSpace, "\\(") 
docs <- tm_map(docs, toSpace, "\\)") 
docs <- tm_map(docs, toSpace, "\\·")
docs <- tm_map(docs, toSpace, "\\…")
docs <- tm_map(docs, toSpace, "\\/")
docs <- tm_map(docs, removePunctuation)
docs <- tm_map(docs, content_transformer(tolower))
docs <- tm_map(docs, removeWords, stopwords("english"))
docs <- tm_map(docs, removeNumbers)
words_to_remove <- c("don","qld","ist","kw","ac","ve","mo","won", "read","more", "show", "details")
docs <- tm_map(docs, removeWords, words_to_remove)
docs <- tm_map(docs, toSpace, "\\b[a-z]\\b")
docs <- tm_map(docs, stripWhitespace)

unname(sapply(docs, as.character))

# ==============================================================================
# PART 2: SENTIMENT ANALYSIS & LEXICON COMPARISON 
# ==============================================================================
message("Running Lexicon Evaluations...")
corpus_text_vector <- sapply(docs, as.character)

# Obtain sentiment vectors via Syuzhet, Bing, and AFINN methods
syuzhet_vector <- get_sentiment(corpus_text_vector, method = "syuzhet")
bing_vector    <- get_sentiment(corpus_text_vector, method = "bing")
afinn_vector   <- get_sentiment(corpus_text_vector, method = "afinn")

# Compare summaries of the evaluations using simple print
message("\n--- Syuzhet Vector Summary ---")
print(summary(syuzhet_vector))

message("\n--- Bing Vector Summary ---")
print(summary(bing_vector))

message("\n--- AFINN Vector Summary ---")
print(summary(afinn_vector))

# 4. Construct a Sign Matrix tracking vector alignment for top rows
comparison_matrix <- rbind(
  Syuzhet = sign(head(syuzhet_vector)),
  Bing    = sign(head(bing_vector)),
  AFINN   = sign(head(afinn_vector))
)
message("\n--- Lexicon Sign Alignment Matrix ---")
print(comparison_matrix)

# ==============================================================================
# PART 3: EMOTION CLASSIFICATION & VISUALIZATION (TASK 3.2)
# ==============================================================================

message("\nPerforming NRC Emotion Classification...")

# Extract the fully cleaned text vector
corpus_text_vector <- sapply(docs, as.character)

# Generate emotion dataframe using the cleaned text
emotion_df <- get_nrc_sentiment(corpus_text_vector)
print(head(emotion_df, 10))

# Transpose and aggregate counts for plotting
td <- data.frame(t(emotion_df))
td_new <- data.frame(rowSums(td))
names(td_new)[1] <- "count"
td_new <- cbind("sentiment" = rownames(td_new), td_new)
rownames(td_new) <- NULL

# Isolate core emotions (Rows 1 to 8: anger through trust)
emotions_only <- td_new[1:8, ]

# Plot 1: Count of words associated with each discrete emotion
plot1 <- ggplot(data = emotions_only, aes(x = reorder(sentiment, -count), y = count, fill = sentiment)) +
  geom_bar(stat = "identity") +
  theme_minimal() +
  labs(title = "AirTouch Consumer Feedback - Emotion Distribution",
       x = "Emotion Classification", 
       y = "Word Association Count") +
  theme(legend.position = "none")

print(plot1)

# ==============================================================================
# PART 4: POSITIVE AND NEGATIVE WORDS 
# ==============================================================================

message("\nExtracting Word Frequencies for Sentiment Classes...")

# Build the data frame for tokenization from your processed text vector
text_df <- data.frame(text = corpus_text_vector, stringsAsFactors = FALSE)
word_tokens <- text_df %>%
  unnest_tokens(word, text) %>%
  anti_join(stop_words, by = "word") 

# Cross-reference tokens with the Bing sentiment dictionary
bing_word_counts <- word_tokens %>%
  inner_join(get_sentiments("bing"), by = "word", relationship = "many-to-many") %>%
  count(word, sentiment, sort = TRUE)

# Filter out top Positive and Negative expressions
top_words <- bing_word_counts %>%
  group_by(sentiment) %>%
  slice_max(n, n = 20) %>%
  ungroup()

print(top_words)

# Plot 2: Most Common Sentiment Words Contributions
plot2 <- ggplot(top_words, aes(x = reorder(word, n), y = n, fill = sentiment)) +
  geom_col(show.legend = FALSE) +
  facet_wrap(~sentiment, scales = "free_y") +
  labs(title = "Most Common Positive and Negative Terms in AirTouch Data",
       x = NULL,
       y = "Frequency Contribution") +
  coord_flip() +
  theme_minimal()

print(plot2)

# ==============================================================================
# PART 5: VISUALIZING SENTIMENT THEMES VIA WORD CLOUDS
# ==============================================================================

message("\nGenerating Positive and Negative Word Clouds...")

# Ensure the wordcloud package is loaded
library(wordcloud)
library(RColorBrewer)

# 1. Isolate and count words matching NEGATIVE sentiment (Complaint Themes)
negative_words <- word_tokens %>%
  inner_join(get_sentiments("bing"), by = "word", relationship = "many-to-many") %>%
  filter(sentiment == "negative") %>%
  count(word, sort = TRUE)

# 2. Isolate and count words matching POSITIVE sentiment
positive_words <- word_tokens %>%
  inner_join(get_sentiments("bing"), by = "word", relationship = "many-to-many") %>%
  filter(sentiment == "positive") %>%
  count(word, sort = TRUE)

# 3. Plot the Negative Word Cloud (Complaints & Pain Points)
dev.new(width = 6, height = 6) # Opens a fresh window for the first plot if needed
set.seed(123) # For reproducibility of word placement

message("Rendering Negative Word Cloud...")
wordcloud(
  words = negative_words$word, 
  freq = negative_words$n, 
  min.freq = 1,              # Includes words that appear at least once
  max.words = 40,            # Limits to top 40 complaint terms for readability
  random.order = FALSE,      # Places the most frequent complaints in the center
  rot.per = 0.35,            # Rotates 35% of the words vertically
  colors = brewer.pal(8, "Reds")[4:8] # Uses a professional gradient of dark reds
)
title(main = "AirTouch Consumer Feedback - Core Complaint Themes", line = -1)

# 4. Plot the Positive Word Cloud (Success Drivers)
dev.new(width = 6, height = 6)
set.seed(123)

message("Rendering Positive Word Cloud...")
wordcloud(
  words = positive_words$word, 
  freq = positive_words$n, 
  min.freq = 1, 
  max.words = 40, 
  random.order = FALSE, 
  rot.per = 0.35, 
  colors = brewer.pal(8, "Greens")[4:8] # Uses a professional gradient of dark greens
)
title(main = "AirTouch Consumer Feedback - Positive Drivers", line = -1)
# ==============================================================================
# PART 6: REFINED REVIEW SENTIMENT & TF-IDF THEME EXTRACTION
# ==============================================================================
message("\nCalculating Review-Level Scores and Enhanced Themes...")

review_base_df <- data.frame(
  Review_ID = metadata_df$Review_ID,
  Recency   = metadata_df$Recency,
  Text      = sapply(docs, as.character),
  stringsAsFactors = FALSE
)

# A. Calculate Sentiment Scores (using reliable Bing logic)
review_scores <- review_base_df %>%
  unnest_tokens(word, Text) %>%
  inner_join(get_sentiments("bing"), by = "word", relationship = "many-to-many") %>%
  mutate(score_val = ifelse(sentiment == "positive", 1, -1)) %>%
  group_by(Review_ID) %>%
  summarise(Net_Sentiment_Score = sum(score_val), .groups = "drop")

# B. THEME EXTRACTION: Use TF-IDF instead of raw word counts
# Expanded blacklist to catch unhelpful contextual nouns and text artifacts
system_noise <- c("app", "airtouch", "air", "touch", "system", "unit", "screen", 
                  "read", "auto", "mode", "zone", "zones", "controller")

review_themes_tfidf <- review_base_df %>%
  unnest_tokens(word, Text) %>%
  anti_join(stop_words, by = "word") %>%
  filter(!word %in% system_noise) %>%
  count(Review_ID, word) %>%
  # Calculate TF-IDF weights for every word per review
  bind_tf_idf(word, Review_ID, n) %>% 
  group_by(Review_ID) %>%
  # Select the top 2 highest-scoring unique terms per review
  slice_max(tf_idf, n = 2, with_ties = FALSE) %>% 
  summarise(Prevailing_Theme = paste(word, collapse = ", "), .groups = "drop")

# Merge metrics back onto master records
metadata_with_themes <- metadata_df %>%
  left_join(review_scores, by = "Review_ID") %>%
  left_join(review_themes_tfidf, by = "Review_ID") %>%
  mutate(
    Net_Sentiment_Score = ifelse(is.na(Net_Sentiment_Score), 0, Net_Sentiment_Score),
    Prevailing_Theme    = ifelse(is.na(Prevailing_Theme) | Prevailing_Theme == "", "General Feedback", Prevailing_Theme)
  )

print((metadata_with_themes[, c("Review_ID", "Author_Name", "Recency", "Net_Sentiment_Score", "Prevailing_Theme")]))

# ==============================================================================
# PART 6.5: INDIVIDUAL REVIEW SENTIMENT RANK-ORDER VISUALIZATION
# ==============================================================================
message("\nSorting reviews and generating individual sentiment distribution plot...")

# Sort the metadata dataset by Net_Sentiment_Score (ascending order)
metadata_sorted <- metadata_with_themes %>%
  arrange(Net_Sentiment_Score) %>%
  mutate(
    # Construct descriptive, unique character strings for the chart's axis labels
    Chart_Label = paste0("ID ", Review_ID, ": ", Author_Name, " (", Recency, ")"),
    # Define a clean categorical color mapping flag dynamically
    Color_Group = case_when(
      Net_Sentiment_Score > 0  ~ "Positive",
      Net_Sentiment_Score < 0  ~ "Negative",
      TRUE                     ~ "Neutral"
    )
  )

metadata_sorted$Chart_Label <- factor(metadata_sorted$Chart_Label, levels = metadata_sorted$Chart_Label)
plot_individual_sentiment <- ggplot(metadata_sorted, aes(x = Chart_Label, y = Net_Sentiment_Score, fill = Color_Group)) +
  geom_col(color = "white", width = 0.75, show.legend = FALSE) +
  scale_fill_manual(values = c("Positive" = "#2ecc71", "Negative" = "#e74c3c", "Neutral" = "#95a5a6")) +
  coord_flip() +
  geom_hline(yintercept = 0, color = "#34495e", size = 0.6) +
  geom_text(aes(
    label = ifelse(Net_Sentiment_Score >= 0, paste0("+", Net_Sentiment_Score), as.character(Net_Sentiment_Score)),
    hjust = ifelse(Net_Sentiment_Score >= 0, -0.3, 1.3)
  ), fontface = "bold", size = 2.5, color = "#2c3e50") +
  
  theme_minimal() +
  expand_limits(y = c(min(metadata_sorted$Net_Sentiment_Score) - 1.5, max(metadata_sorted$Net_Sentiment_Score) + 1.5)) +
  
  labs(
    title = "Individual AirTouch Review Sentiment Magnitudes",
    subtitle = "Rank-Ordered Sentiment Distribution across Consumer Accounts (Bing Lexicon Matrix)",
    x = "Consumer Review Profile Index",
    y = "Net Sentiment Score Contribution Value"
  ) +
  theme(
    plot.title = element_text(face = "bold", size = 13, color = "#2c3e50"),
    plot.subtitle = element_text(size = 10, color = "#7f8c8d"),
    axis.text.y = element_text(size = 8, face = "plain", color = "#34495e"),
    axis.text.x = element_text(size = 9),
    panel.grid.minor = element_blank(),
    panel.grid.major.y = element_blank()
  )

print(plot_individual_sentiment)

# ==============================================================================
# PART 6.6: INDIVIDUAL REVIEW SENTIMENT CHRONOLOGICAL VISUALIZATION
# ==============================================================================

recency_order <- c("6y", "5y", "4y", "3y", "2y", "1y", "12mo", "9mo", "7mo", "3mo")

metadata_recency_sorted <- metadata_with_themes %>%
  mutate(Recency_Order_Ref = match(Recency, recency_order)) %>%
  arrange(Recency_Order_Ref, Review_ID) %>%
  mutate(
    Chart_Label = paste0("[", Recency, "] ID ", Review_ID, ": ", Author_Name),
    Color_Group = case_when(
      Net_Sentiment_Score > 0  ~ "Positive",
      Net_Sentiment_Score < 0  ~ "Negative",
      TRUE                     ~ "Neutral"
    )
  )

metadata_recency_sorted$Chart_Label <- factor(
  metadata_recency_sorted$Chart_Label, 
  levels = rev(metadata_recency_sorted$Chart_Label)
)

plot_chronological_sentiment <- ggplot(metadata_recency_sorted, aes(x = Chart_Label, y = Net_Sentiment_Score, fill = Color_Group)) +
  geom_col(color = "white", width = 0.75, show.legend = FALSE) +
  scale_fill_manual(values = c("Positive" = "#2ecc71", "Negative" = "#e74c3c", "Neutral" = "#95a5a6")) +
  coord_flip() +
  geom_hline(yintercept = 0, color = "#34495e", size = 0.6) +
  geom_text(aes(
    label = ifelse(Net_Sentiment_Score >= 0, paste0("+", Net_Sentiment_Score), as.character(Net_Sentiment_Score)),
    hjust = ifelse(Net_Sentiment_Score >= 0, -0.3, 1.3)
  ), fontface = "bold", size = 2.5, color = "#2c3e50") +
  theme_minimal() +
  expand_limits(y = c(min(metadata_recency_sorted$Net_Sentiment_Score) - 1.5, max(metadata_recency_sorted$Net_Sentiment_Score) + 1.5)) +
  labs(
    title = "Individual AirTouch Review Sentiment Over Time",
    subtitle = "Chronological Sentiment Stream Tracking Historical Performance (Oldest to Newest)",
    x = "Timeline Account Index (Oldest at Top)",
    y = "Net Sentiment Score Contribution Value"
  ) +
  theme(
    plot.title = element_text(face = "bold", size = 13, color = "#2c3e50"),
    plot.subtitle = element_text(size = 10, color = "#7f8c8d"),
    axis.text.y = element_text(size = 8, face = "plain", color = "#34495e"),
    axis.text.x = element_text(size = 9),
    panel.grid.minor = element_blank(),
    panel.grid.major.y = element_blank()
  )

print(plot_chronological_sentiment)

# ==============================================================================
# PART 7: CHRONOLOGICAL AGGREGATION & BIDIRECTIONAL BAR VISUALIZATION
# ==============================================================================
message("\nAggregating Clean Sentiment Framework Trends by Recency...")

library(dplyr)
library(ggplot2)
library(stringr)

# 1. Establish an explicit chronological order and map the audited thematic insights
timeline_clean_themes <- data.frame(
  Recency     = c("6y", "5y", "4y", "3y", "12mo", "9mo", "7mo", "3mo"),
  Time_Index  = 1:8,
  Group_Theme = c(
    "Variable Installer Setup Quality",  
    "Wireless Interference & Hardware Failures",    
    "Firmware & Local WiFi Drops", 
    "Unresponsive Support Teams",  
    "Airflow Calculation Bugs",    
    "Spill Zone Thermal Instability",      
    "Defective Auto-Mode Logic",   
    "Spiking Utility & Power Bills"
  ),
  stringsAsFactors = FALSE
)

# 2. Extract the actual mathematical mean sentiment from review metrics
timeline_final <- metadata_with_themes %>%
  inner_join(timeline_clean_themes, by = "Recency") %>%
  group_by(Time_Index, Recency, Group_Theme) %>%
  summarise(Mean_Sentiment = mean(Net_Sentiment_Score), .groups = "drop") %>%
  arrange(Time_Index)

timeline_final$Direction <- ifelse(timeline_final$Mean_Sentiment >= 0, "Positive", "Negative")
timeline_final$Wrapped_Theme <- str_wrap(timeline_final$Group_Theme, width = 15)

print(timeline_final)

# 3. Generate Column Chart
plot_timeline_bar <- ggplot(timeline_final, aes(x = reorder(Recency, Time_Index), y = Mean_Sentiment, fill = Direction)) +
  geom_col(color = "white", width = 0.55, show.legend = FALSE) +
  scale_fill_manual(values = c("Positive" = "#2ecc71", "Negative" = "#e74c3c")) +
  geom_hline(yintercept = 0, color = "#7f8c8d", size = 0.8) +
  geom_text(aes(
    label = Wrapped_Theme, 
    vjust = ifelse(Mean_Sentiment >= 0, -0.4, 1.4),
    hjust = ifelse(Mean_Sentiment >= 0, 0.2, 0.8)
  ), fontface = "bold", size = 3, color = "#2c3e50", angle = 0, lineheight = 0.85) +
  
  theme_minimal() +
  expand_limits(y = c(min(timeline_final$Mean_Sentiment) - 3.5, max(timeline_final$Mean_Sentiment) + 3.5)) +
  
  labs(
    title = "AirTouch Customer Experience Journey Over Time",
    subtitle = "Tracking Net Sentiment Shifts alongside Human-Audited Operational Pain Points",
    x = "Timeline Horizon (Oldest to Newest)",
    y = "Average Net Sentiment Score (Bing Lexicon)"
  ) +
  theme(
    plot.title = element_text(face = "bold", size = 14, color = "#2c3e50"),
    plot.subtitle = element_text(size = 11, color = "#34495e"),
    axis.text.x = element_text(face = "bold", size = 11, color = "#2c3e50"),
    axis.text.y = element_text(size = 10),
    panel.grid.minor = element_blank(),
    panel.grid.major.x = element_line(color = "#ecf0f1")
  )

print(plot_timeline_bar)



# ==============================================================================
# PART 8: EMOTION EVOLUTION JOURNEY OVER TIME (STACKED PERCENTAGE BAR CHART)
# ==============================================================================
message("\nAnalyzing Emotion Evolution Trends across Time Horizons...")

library(dplyr)
library(ggplot2)
library(tidyr)

# 1. Establish the identical chronological time map used in Part 7
time_order <- data.frame(
  Recency = c("6y", "5y", "4y", "3y", "12mo", "9mo", "7mo", "3mo"),
  Time_Index = 1:8,
  stringsAsFactors = FALSE
)

# 2. Extract clean text strings, calculate NRC emotions, and bind to Recency markers
review_base_df <- data.frame(
  Recency = metadata_df$Recency,
  Text    = sapply(docs, as.character),
  stringsAsFactors = FALSE
)

emotion_matrix <- get_nrc_sentiment(review_base_df$Text)
emotion_timeline_raw <- cbind(Recency = review_base_df$Recency, emotion_matrix)

# 3. Aggregate scores by time groups and convert to long format for ggplot
emotion_evolution <- emotion_timeline_raw %>%
  inner_join(time_order, by = "Recency") %>%
  group_by(Time_Index, Recency) %>%
  summarise(
    anger        = sum(anger),
    anticipation = sum(anticipation),
    disgust      = sum(disgust),
    fear         = sum(fear),
    joy          = sum(joy),
    sadness      = sum(sadness),
    surprise     = sum(surprise),
    trust        = sum(trust),
    .groups = "drop"
  ) %>%
  # Pivot into a tidy format for stacking
  pivot_longer(
    cols = c(anger, anticipation, disgust, fear, joy, sadness, surprise, trust),
    names_to = "Emotion",
    values_to = "Word_Count"
  ) %>%
  group_by(Time_Index, Recency) %>%
  mutate(Percentage = Word_Count / sum(Word_Count)) %>%
  ungroup() %>%
  arrange(Time_Index)

print(head(emotion_evolution, 16))

# 4. Define a professional, matching emotional color palette
evolution_colors <- c(
  "trust"        = "#2ecc71", # Emerald Green
  "joy"          = "#f1c40f", # Sunflower Yellow
  "anticipation" = "#3498db", # Bright Blue
  "surprise"     = "#9b59b6", # Amethyst Purple
  "sadness"      = "#34495e", # Muted Slate
  "fear"         = "#7f8c8d", # Cool Grey
  "disgust"      = "#d35400", # Dark Orange
  "anger"        = "#e74c3c"  # Alizarin Red
)

# 5. Generate the Stacked Percentage Bar Chart
plot_emotion_evolution <- ggplot(emotion_evolution, aes(
  x = reorder(Recency, Time_Index), 
  y = Percentage, 
  fill = factor(Emotion, levels = c("trust", "joy", "anticipation", "surprise", 
                                    "sadness", "fear", "disgust", "anger"))
)) +
  geom_bar(stat = "identity", position = "fill", width = 0.65, color = "white", size = 0.2) +
  scale_y_continuous(labels = scales::percent_format()) +
  scale_fill_manual(values = evolution_colors) +
  
  theme_minimal() +
  labs(
    title = "AirTouch Emotional Shift Spectrum Over Time",
    subtitle = "Tracking the proportional growth and contraction of core consumer sentiments",
    x = "Timeline Horizon (Oldest to Newest)",
    y = "Relative Sentiment Distribution",
    fill = "Emotion Theme"
  ) +
  theme(
    plot.title = element_text(face = "bold", size = 14, color = "#2c3e50"),
    plot.subtitle = element_text(size = 11, color = "#34495e"),
    axis.text.x = element_text(face = "bold", size = 11, color = "#2c3e50"),
    axis.text.y = element_text(size = 10),
    legend.title = element_text(face = "bold"),
    legend.position = "right",
    panel.grid.minor = element_blank(),
    panel.grid.major.x = element_blank()
  )

print(plot_emotion_evolution)
