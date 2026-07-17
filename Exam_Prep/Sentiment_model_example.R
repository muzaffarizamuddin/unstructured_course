# ==============================================================================
# WORKED EXAMPLE: SENTIMENT ANALYSIS on TeamHealthSentiment.txt
# Course: STQD6114 | Companion to Sentiment_model.R (the fill-in-the-blank template)
#
# This file is NOT a template -- every parameter below is already filled in
# for the TeamHealthSentiment.txt dataset (300 free-text team-health survey
# responses, one per line) so you can run it top-to-bottom tonight and see
# real output before the exam. If a future question uses a DIFFERENT dataset,
# go back to Sentiment_model.R and fill in the ">>> CHANGE" spots instead.
#
# WORKFLOW: read data (VectorSource) -> VCorpus -> clean -> DTM/frequency
#           -> wordcloud variations -> lexicon sentiment scores (syuzhet/
#           bing/afinn/nrc) -> NRC emotions -> positive/negative words+wordclouds
#           -> per-document sentiment ranking
# ==============================================================================

# ------------------------------------------------------------------------
# 0. LIBRARIES
# ------------------------------------------------------------------------
# install.packages(c("tm","syuzhet","ggplot2","tidytext","dplyr","stringr",
#                     "wordcloud","wordcloud2","RColorBrewer"))

library(tm)
library(syuzhet)
library(ggplot2)
library(tidytext)
library(dplyr)
library(stringr)
library(wordcloud)
library(RColorBrewer)
# library(wordcloud2)   # only needed for the wordcloud2() variations below


# ==============================================================================
# 1. LOAD DATA -- VectorSource (one survey response per line)
# ==============================================================================

raw_lines <- readLines("C:/Users/muzaffar.izamuddin/OneDrive - Polyaire Pty Ltd/Desktop/VS Code/unstructured_course/TeamHealthSentiment.txt")
mycorpus  <- VCorpus(VectorSource(raw_lines))

length(mycorpus)               # 300 responses
as.character(mycorpus[[1]])    # "We're a fun team that works well together..."


# ==============================================================================
# 2. DATA CLEANING
# ==============================================================================

toSpace <- content_transformer(function(x, pattern) { gsub(pattern, " ", x) })

docs <- tm_map(mycorpus, toSpace, "-")
docs <- tm_map(docs, toSpace, "–")
docs <- tm_map(docs, toSpace, "’")
docs <- tm_map(docs, toSpace, "‘")
docs <- tm_map(docs, toSpace, "'")

docs <- tm_map(docs, removePunctuation)
docs <- tm_map(docs, content_transformer(tolower))
docs <- tm_map(docs, removeWords, stopwords("english"))
docs <- tm_map(docs, removeNumbers)

# custom noise words: apostrophe was converted to a space BEFORE punctuation
# removal/stopword removal, so contractions like "team's", "we're", "don't"
# leave behind orphan fragments ("s", "re", "don", "t"...) that stopwords()
# can no longer match as whole words -- strip those leftovers explicitly
words_to_remove <- c("s", "t", "re", "ve", "ll", "m", "don", "isn", "wasn",
                      "wouldn", "couldn", "shouldn", "didn", "won")
docs <- tm_map(docs, removeWords, words_to_remove)

docs <- tm_map(docs, stripWhitespace)

# ---- OPTIONAL: stemming (uncomment only for frequency/wordcloud tasks --
#      do NOT stem before the sentiment-scoring sections below, since bing/
#      afinn/nrc lexicons need full word forms) ----
# library(SnowballC)
# docs_stemmed <- tm_map(docs, stemDocument)


# ==============================================================================
# 3. INSPECT CORPUS (check cleaning worked, both doc-by-doc AND as a whole)
# ==============================================================================

as.character(docs[[1]])
for (i in 1:5) {
  print(as.character(docs[[i]]))
}

all_text <- unname(sapply(docs, as.character))
head(all_text)

# scan the WHOLE corpus for leftover non-alphanumeric characters
leftover_chars <- unique(unlist(regmatches(all_text, gregexpr("[^a-z0-9 ]", all_text))))
sort(leftover_chars)   # should be empty/near-empty once cleaning is solid


# ==============================================================================
# 4. TERM FREQUENCY ANALYSIS (frequency, sorting, associations)
# ==============================================================================

dtm <- DocumentTermMatrix(docs)

freq <- colSums(as.matrix(dtm))
ord  <- order(freq, decreasing = TRUE)
freq[ord][1:20]                       # top 20 most frequent terms overall
                                       # (expect: "team", "good", "great", "health", "work"...)

freq_df <- data.frame(TERM = names(freq), FREQ = freq)
freq_df <- freq_df[order(-freq_df$FREQ), ]
head(freq_df, 10)

findFreqTerms(dtm, lowfreq = 20)                    # words appearing at least 20 times

findAssocs(dtm, "health", 0.15)                      # words associated with "health"
findAssocs(dtm, "support", 0.15)                     # words associated with "support"
findAssocs(dtm, "projectx", 0.15)                    # ProjectX comes up a lot -- what's it associated with?

# multi-term version -- association for several target words at once
findAssocs(dtm, terms = c("team", "health", "support"), corlimit = 0.15)

# associations for every word that already passes a frequency threshold
findAssocs(dtm, terms = findFreqTerms(dtm, lowfreq = 30), corlimit = 0.15)

# bar chart of the more common terms (freq >= 10, otherwise 300 responses -> too cluttered)
freq_subset <- subset(freq_df, FREQ >= 20)
ggplot(freq_subset, aes(x = reorder(TERM, -FREQ), y = FREQ)) +
  geom_bar(stat = "identity") +
  theme(axis.text.x = element_text(angle = 90, hjust = 1, vjust = 0.5)) +
  ggtitle("Team Health Survey -- Document Term Frequency") +
  xlab("Terms") + ylab("Frequency")

# quick base-R alternative: barplot of the top 10 frequent words
barplot(freq_df[1:10, ]$FREQ, las = 2, names.arg = freq_df[1:10, ]$TERM,
        col = "lightgreen", main = "Top 10 Most Frequent Words",
        ylab = "Word Frequencies")

# ---- Alternative frequency route: TermDocumentMatrix (rows = terms) ----
tdm_alt   <- TermDocumentMatrix(docs)
tdm_alt_m <- as.matrix(tdm_alt)
tdm_alt_v <- sort(rowSums(tdm_alt_m), decreasing = TRUE)
tdm_alt_d <- data.frame(word = names(tdm_alt_v), freq = tdm_alt_v)
head(tdm_alt_d, 5)     # same ranking as freq_df above, built the "other way round"


# ==============================================================================
# 5. WORDCLOUD VARIATIONS
# ==============================================================================

# a) basic wordcloud, minimum frequency filter
wordcloud(names(freq), freq, min.freq = 3)

# b) focus on more common words only
wordcloud(names(freq), freq, min.freq = 10)

# c) coloured by a Brewer palette, most frequent centred
set.seed(1234)
wordcloud(names(freq), freq,
          max.words = 100, random.order = FALSE, rot.per = 0.35,
          colors = brewer.pal(8, "Dark2"))

# display.brewer.all()   # uncomment to preview every available palette name

# d) wordcloud2 (interactive HTML widget, alternate shapes)
# library(wordcloud2)
# wordcloud2(freq_df, size = 0.5)
# wordcloud2(freq_df, size = 0.5, color = "random-light", backgroundColor = "black")
# wordcloud2(freq_df, shape = "star", size = 0.5)


# ==============================================================================
# 6. SENTIMENT SCORING -- syuzhet / bing / afinn / nrc
# ==============================================================================

corpus_text_vector <- sapply(docs, as.character)

syuzhet_vector <- get_sentiment(corpus_text_vector, method = "syuzhet")
bing_vector    <- get_sentiment(corpus_text_vector, method = "bing")
afinn_vector   <- get_sentiment(corpus_text_vector, method = "afinn")
nrc_vector     <- get_sentiment(corpus_text_vector, method = "nrc")

summary(syuzhet_vector)
summary(bing_vector)
summary(afinn_vector)
summary(nrc_vector)
# expect an overwhelmingly positive skew across all four lexicons -- this is a
# team-HEALTH survey, so "good/great/strong/fun/trust" dominate over the
# comparatively rarer "stress/frustrated/uncertain" responses

# quick agreement check across lexicons (sign = direction, +/-, of first few docs)
rbind(Syuzhet = sign(head(syuzhet_vector)),
      Bing    = sign(head(bing_vector)),
      AFINN   = sign(head(afinn_vector)),
      NRC     = sign(head(nrc_vector)))

# ---- OPTIONAL: simple custom-dictionary sentiment scorer ----
mysentiment <- function(words) {
  mydictpos <- c("good", "great", "strong", "fun", "trust", "collaborative", "positive")
  mydictneg <- c("stress", "frustrat", "uncertain", "weak", "poor", "struggl", "anxious")

  pos_score <- sum(!is.na(match(words, mydictpos)))
  neg_score <- -1 * sum(!is.na(match(words, mydictneg)))
  pos_score + neg_score
}

doc1_words <- unlist(strsplit(corpus_text_vector[1], "\\s+"))
mysentiment(doc1_words)     # score for response #1 using the custom dictionary


# ==============================================================================
# 7. NRC EMOTION CLASSIFICATION + PLOT
# ==============================================================================

emotion_df <- get_nrc_sentiment(corpus_text_vector)
head(emotion_df, 10)

td     <- data.frame(t(emotion_df))
td_new <- data.frame(count = rowSums(td))
td_new <- cbind(sentiment = rownames(td_new), td_new)
rownames(td_new) <- NULL

emotions_only <- td_new[1:8, ]     # anger..trust (drop the pos/neg total rows)

ggplot(emotions_only, aes(x = reorder(sentiment, -count), y = count, fill = sentiment)) +
  geom_bar(stat = "identity") +
  theme_minimal() +
  labs(title = "Team Health Survey -- Emotion Distribution",
       x = "Emotion Classification", y = "Word Association Count") +
  theme(legend.position = "none")
# expect "trust" and "joy" to dominate over "fear"/"anger"/"disgust"

# ---- Alternative: emotions as a PERCENTAGE of total words, horizontal bars ----
barplot(
  sort(colSums(prop.table(emotion_df[, 1:8]))),
  horiz = TRUE,
  cex.names = 0.7,
  las = 1,
  main = "Team Health Survey -- Emotions in Text (%)",
  xlab = "Percentage"
)


# ==============================================================================
# 8. POSITIVE / NEGATIVE WORDS (Bing) + SEPARATE WORDCLOUDS
# ==============================================================================

text_df <- data.frame(text = corpus_text_vector, stringsAsFactors = FALSE)

word_tokens <- text_df %>%
  unnest_tokens(word, text) %>%
  anti_join(stop_words, by = "word")

bing_word_counts <- word_tokens %>%
  inner_join(get_sentiments("bing"), by = "word", relationship = "many-to-many") %>%
  count(word, sentiment, sort = TRUE)

top_words <- bing_word_counts %>%
  group_by(sentiment) %>%
  slice_max(n, n = 20) %>%
  ungroup()

ggplot(top_words, aes(x = reorder(word, n), y = n, fill = sentiment)) +
  geom_col(show.legend = FALSE) +
  facet_wrap(~sentiment, scales = "free_y") +
  coord_flip() +
  labs(title = "Team Health Survey -- Most Common Positive/Negative Terms",
       x = NULL, y = "Frequency")

negative_words <- bing_word_counts %>% filter(sentiment == "negative")
positive_words <- bing_word_counts %>% filter(sentiment == "positive")

set.seed(123)
wordcloud(words = negative_words$word, freq = negative_words$n,
          min.freq = 1, max.words = 40, random.order = FALSE, rot.per = 0.35,
          colors = brewer.pal(8, "Reds")[4:8])
title(main = "Negative Themes", line = -1)

set.seed(123)
wordcloud(words = positive_words$word, freq = positive_words$n,
          min.freq = 1, max.words = 40, random.order = FALSE, rot.per = 0.35,
          colors = brewer.pal(8, "Greens")[4:8])
title(main = "Positive Themes", line = -1)


# ==============================================================================
# 9. PER-DOCUMENT SENTIMENT SCORE + RANKED BAR CHART
# ==============================================================================

doc_df <- data.frame(
  Doc_ID = seq_along(corpus_text_vector),
  Text   = corpus_text_vector,
  stringsAsFactors = FALSE
)

doc_scores <- doc_df %>%
  unnest_tokens(word, Text) %>%
  inner_join(get_sentiments("bing"), by = "word", relationship = "many-to-many") %>%
  mutate(score_val = ifelse(sentiment == "positive", 1, -1)) %>%
  group_by(Doc_ID) %>%
  summarise(Net_Sentiment_Score = sum(score_val), .groups = "drop")

doc_scores_full <- doc_df %>%
  left_join(doc_scores, by = "Doc_ID") %>%
  mutate(Net_Sentiment_Score = ifelse(is.na(Net_Sentiment_Score), 0, Net_Sentiment_Score))

# most positive / most negative responses at a glance
head(doc_scores_full %>% arrange(desc(Net_Sentiment_Score)), 10)   # most positive
head(doc_scores_full %>% arrange(Net_Sentiment_Score), 10)         # most negative (or 0)

# with 300 responses, plotting all of them is unreadable -- slice to the
# top 15 most positive + bottom 15 most negative/neutral for the chart
doc_scores_sorted <- doc_scores_full %>% arrange(Net_Sentiment_Score)
doc_scores_plot <- bind_rows(head(doc_scores_sorted, 15), tail(doc_scores_sorted, 15)) %>%
  distinct(Doc_ID, .keep_all = TRUE) %>%
  arrange(Net_Sentiment_Score) %>%
  mutate(
    Chart_Label = paste0("Doc ", Doc_ID),
    Color_Group = case_when(
      Net_Sentiment_Score > 0 ~ "Positive",
      Net_Sentiment_Score < 0 ~ "Negative",
      TRUE ~ "Neutral"
    )
  )
doc_scores_plot$Chart_Label <- factor(doc_scores_plot$Chart_Label,
                                       levels = doc_scores_plot$Chart_Label)

ggplot(doc_scores_plot, aes(x = Chart_Label, y = Net_Sentiment_Score, fill = Color_Group)) +
  geom_col(color = "white", width = 0.75, show.legend = FALSE) +
  scale_fill_manual(values = c("Positive" = "#2ecc71", "Negative" = "#e74c3c", "Neutral" = "#95a5a6")) +
  coord_flip() +
  geom_hline(yintercept = 0, color = "#34495e", size = 0.6) +
  theme_minimal() +
  labs(title = "Team Health Survey -- Most Positive & Most Negative Responses",
       x = "Response", y = "Net Sentiment Score (Bing)")

# ==============================================================================
# END OF SCRIPT
# ==============================================================================
