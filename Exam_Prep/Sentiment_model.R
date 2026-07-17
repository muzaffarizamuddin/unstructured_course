# ==============================================================================
# MODEL SCRIPT: SENTIMENT ANALYSIS + TERM FREQUENCY + WORDCLOUD VARIATIONS
# Course: STQD6114 | Copy-paste template for the final exam
#
# HOW TO USE THIS FILE:
#   Every place you might need to edit for a different exam question is
#   marked with a line starting "# >>> CHANGE:" -- search for ">>> CHANGE"
#   to jump between all the settings you may need to touch.
#
# WORKFLOW: read data (Vector/Dir/csv) -> VCorpus -> clean -> DTM/frequency
#           -> wordcloud variations -> lexicon sentiment scores (syuzhet/
#           bing/afinn) -> NRC emotions -> positive/negative words+wordclouds
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
# 1. LOAD DATA -- pick ONE of the options below depending on the exam question
# ==============================================================================

# ---- Option A: plain text file, one document/response per line (VectorSource) ----
# >>> CHANGE: path to the exam's text file
raw_lines <- readLines("C:/path/to/your/Data_File.txt")
mycorpus  <- VCorpus(VectorSource(raw_lines))

# ---- Option B: folder of separate .txt files (DirSource) ----
# >>> CHANGE: uncomment and set the folder path if the exam gives files, not one txt
# mytext   <- DirSource("C:/path/to/your/Data_Folder")
# mycorpus <- VCorpus(mytext)

# ---- Option C: CSV / data frame with a text column (DataframeSource) ----
# >>> CHANGE: uncomment, set path + column names if the exam gives a CSV
# raw_df   <- read.csv("C:/path/to/your/Data.csv", stringsAsFactors = FALSE)
# raw_df   <- data.frame(doc_id = seq_len(nrow(raw_df)), text = raw_df$review_text_column)
# mycorpus <- VCorpus(DataframeSource(raw_df))

# ---- Option D: messy CSV/txt where rows are split across many columns ----
# >>> CHANGE: only use this if a normal read gives ragged/broken rows
# data   <- read.table(file.choose(), fill = TRUE, header = FALSE)
# data   <- t(data)
# data_1 <- sapply(1:ncol(data), function(x) {
#              trimws(paste(data[, x], collapse = " "), which = "right")
#            })
# mycorpus <- VCorpus(VectorSource(data_1))

length(mycorpus)               # sanity check: number of documents
as.character(mycorpus[[1]])    # sanity check: first document's raw text


# ==============================================================================
# 2. DATA CLEANING
# ==============================================================================

toSpace <- content_transformer(function(x, pattern) { gsub(pattern, " ", x) })

docs <- tm_map(mycorpus, toSpace, "-")
docs <- tm_map(docs, toSpace, "–")
docs <- tm_map(docs, toSpace, "’")
docs <- tm_map(docs, toSpace, "‘")
docs <- tm_map(docs, toSpace, "'")

# social-media / survey-export style noise (mentions, slashes, pipe delimiters)
# >>> CHANGE: only needed if the exam text has these characters (e.g. tweets, exports)
docs <- tm_map(docs, toSpace, "@")
docs <- tm_map(docs, toSpace, "/")
docs <- tm_map(docs, toSpace, "\\|")

docs <- tm_map(docs, removePunctuation)
docs <- tm_map(docs, content_transformer(tolower))
docs <- tm_map(docs, removeWords, stopwords("english"))
docs <- tm_map(docs, removeNumbers)

# >>> CHANGE: add your own custom stopwords/noise words here based on what
#             you see when you inspect the corpus/frequency table below
words_to_remove <- c("read", "more", "show", "details")
docs <- tm_map(docs, removeWords, words_to_remove)

docs <- tm_map(docs, stripWhitespace)

# ---- OPTIONAL: stemming (reduces words to their root, e.g. "working" -> "work") ----
# >>> CHANGE: only stem if the exam question explicitly asks for it, e.g. for
#             frequency/wordcloud tasks. CAUTION: do NOT stem before running
#             get_sentiment()/get_nrc_sentiment() (Sections 6-8) -- the bing/
#             afinn/nrc lexicons expect full word forms, and stemmed words
#             (e.g. "collabor") will fail to match and silently lower your
#             sentiment scores. Keep a separate `docs_stemmed` copy instead.
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
sort(leftover_chars)


# ==============================================================================
# 4. TERM FREQUENCY ANALYSIS (frequency, sorting, associations)
# ==============================================================================

dtm <- DocumentTermMatrix(docs)

# OPTIONAL stricter control (uncomment/adjust if the exam asks for it)
# >>> CHANGE: word length range / global frequency bounds
# dtm <- DocumentTermMatrix(docs, control = list(wordLengths = c(2, 20),
#                                                 bounds = list(global = c(1, 30))))

freq <- colSums(as.matrix(dtm))
ord  <- order(freq, decreasing = TRUE)
freq[ord][1:20]                       # top 20 most frequent terms overall

freq_df <- data.frame(TERM = names(freq), FREQ = freq)
freq_df <- freq_df[order(-freq_df$FREQ), ]
head(freq_df, 10)

# >>> CHANGE: lowfreq threshold -- "words appearing at least N times"
findFreqTerms(dtm, lowfreq = 5)

# >>> CHANGE: target word + correlation threshold -- "words associated with X"
findAssocs(dtm, "team", 0.2)

# multi-term version -- association for several target words at once
# >>> CHANGE: the vector of words and the correlation limit
findAssocs(dtm, terms = c("good", "work", "team"), corlimit = 0.25)

# associations for every word that already passes a frequency threshold
# (handy when the exam says "find associations for the most frequent terms")
# >>> CHANGE: lowfreq / corlimit
findAssocs(dtm, terms = findFreqTerms(dtm, lowfreq = 10), corlimit = 0.25)

# >>> CHANGE: filter threshold for plotting only reasonably frequent terms
freq_subset <- subset(freq_df, FREQ >= 3)
ggplot(freq_subset, aes(x = reorder(TERM, -FREQ), y = FREQ)) +
  geom_bar(stat = "identity") +
  theme(axis.text.x = element_text(angle = 90, hjust = 1, vjust = 0.5)) +
  ggtitle("Document Term Frequency") +
  xlab("Terms") + ylab("Frequency")

# quick base-R alternative: barplot of the top N frequent words
# >>> CHANGE: 1:5 -> however many top words the question asks for
barplot(freq_df[1:5, ]$FREQ, las = 2, names.arg = freq_df[1:5, ]$TERM,
        col = "lightgreen", main = "Top 5 Most Frequent Words",
        ylab = "Word Frequencies")

# ---- Alternative frequency route: TermDocumentMatrix (rows = terms) ----
# some exam phrasing builds the matrix "the other way round" (terms as rows,
# documents as columns) -- the ranking/output is identical to freq_df above,
# just built via rowSums instead of colSums
tdm_alt   <- TermDocumentMatrix(docs)
tdm_alt_m <- as.matrix(tdm_alt)
tdm_alt_v <- sort(rowSums(tdm_alt_m), decreasing = TRUE)
tdm_alt_d <- data.frame(word = names(tdm_alt_v), freq = tdm_alt_v)
head(tdm_alt_d, 5)


# ==============================================================================
# 5. WORDCLOUD VARIATIONS
# ==============================================================================

# ---- a) basic wordcloud, minimum frequency filter ----
# >>> CHANGE: min.freq controls how rare a word can be and still show up
wordcloud(names(freq), freq, min.freq = 1)

# ---- b) focus on more common words only ----
# >>> CHANGE: raise min.freq to reduce clutter
wordcloud(names(freq), freq, min.freq = 5)

# ---- c) coloured by a Brewer palette, most frequent centred ----
# >>> CHANGE: try other palettes -- run display.brewer.all() to see options
set.seed(1234)
wordcloud(names(freq), freq,
          max.words = 100, random.order = FALSE, rot.per = 0.35,
          colors = brewer.pal(8, "Dark2"))

# display.brewer.all()   # uncomment to preview every available palette name

# ---- d) wordcloud2 (interactive HTML widget, alternate shapes) ----
# library(wordcloud2)
# wordcloud2(freq_df, size = 0.5)
# wordcloud2(freq_df, size = 0.5, color = "random-light", backgroundColor = "black")
# wordcloud2(freq_df, shape = "star", size = 0.5)
# wordcloud2(freq_df, shape = "circle", size = 0.5)


# ==============================================================================
# 6. SENTIMENT SCORING -- syuzhet / bing / afinn
# ==============================================================================

corpus_text_vector <- sapply(docs, as.character)

syuzhet_vector <- get_sentiment(corpus_text_vector, method = "syuzhet")
bing_vector    <- get_sentiment(corpus_text_vector, method = "bing")
afinn_vector   <- get_sentiment(corpus_text_vector, method = "afinn")
nrc_vector     <- get_sentiment(corpus_text_vector, method = "nrc")   # nrc as a single +/- score (not the 8-emotion breakdown -- that's Section 7)

summary(syuzhet_vector)
summary(bing_vector)
summary(afinn_vector)
summary(nrc_vector)

# quick agreement check across lexicons (sign = direction, +/-, of first few docs)
rbind(Syuzhet = sign(head(syuzhet_vector)),
      Bing    = sign(head(bing_vector)),
      AFINN   = sign(head(afinn_vector)),
      NRC     = sign(head(nrc_vector)))

# ---- OPTIONAL: simple custom-dictionary sentiment scorer ----
# useful if the exam asks you to score sentiment WITHOUT a package lexicon,
# using your own list of positive/negative words (e.g. domain-specific terms)
# >>> CHANGE: mydictpos / mydictneg to whatever word lists the question gives
mysentiment <- function(words) {
  mydictpos <- c("good", "great", "happy", "strong", "trust")
  mydictneg <- c("bad", "poor", "weak", "stress", "frustrat")

  pos_score <- sum(!is.na(match(words, mydictpos)))
  neg_score <- -1 * sum(!is.na(match(words, mydictneg)))
  pos_score + neg_score
}

# apply to one document's tokenised words, e.g.:
# doc1_words <- unlist(strsplit(corpus_text_vector[1], "\\s+"))
# mysentiment(doc1_words)


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
  labs(title = "Emotion Distribution",       # >>> CHANGE: plot title to match the dataset
       x = "Emotion Classification", y = "Word Association Count") +
  theme(legend.position = "none")

# quick one-liner alternative using qplot/quickplot instead of full ggplot()
# quickplot(sentiment, data = emotions_only, weight = count, geom = "bar",
#           fill = sentiment, ylab = "count") + ggtitle("Emotion Distribution")

# ---- Alternative: emotions as a PERCENTAGE of total words, horizontal bars ----
barplot(
  sort(colSums(prop.table(emotion_df[, 1:8]))),
  horiz = TRUE,
  cex.names = 0.7,
  las = 1,
  main = "Emotions in Text (%)",   # >>> CHANGE: title
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

# >>> CHANGE: n = how many top pos/neg words to keep for the bar chart
top_words <- bing_word_counts %>%
  group_by(sentiment) %>%
  slice_max(n, n = 20) %>%
  ungroup()

ggplot(top_words, aes(x = reorder(word, n), y = n, fill = sentiment)) +
  geom_col(show.legend = FALSE) +
  facet_wrap(~sentiment, scales = "free_y") +
  coord_flip() +
  labs(title = "Most Common Positive and Negative Terms", x = NULL, y = "Frequency")

negative_words <- bing_word_counts %>% filter(sentiment == "negative")
positive_words <- bing_word_counts %>% filter(sentiment == "positive")

# >>> CHANGE: max.words / colours to taste
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

# sort by sentiment, most negative to most positive
doc_scores_sorted <- doc_scores_full %>%
  arrange(Net_Sentiment_Score) %>%
  mutate(
    Chart_Label = paste0("Doc ", Doc_ID),
    Color_Group = case_when(
      Net_Sentiment_Score > 0 ~ "Positive",
      Net_Sentiment_Score < 0 ~ "Negative",
      TRUE ~ "Neutral"
    )
  )
doc_scores_sorted$Chart_Label <- factor(doc_scores_sorted$Chart_Label,
                                         levels = doc_scores_sorted$Chart_Label)

# >>> CHANGE: for a large dataset, slice to top/bottom N docs before plotting,
#             e.g. bind_rows(head(doc_scores_sorted, 15), tail(doc_scores_sorted, 15))
ggplot(doc_scores_sorted, aes(x = Chart_Label, y = Net_Sentiment_Score, fill = Color_Group)) +
  geom_col(color = "white", width = 0.75, show.legend = FALSE) +
  scale_fill_manual(values = c("Positive" = "#2ecc71", "Negative" = "#e74c3c", "Neutral" = "#95a5a6")) +
  coord_flip() +
  geom_hline(yintercept = 0, color = "#34495e", size = 0.6) +
  theme_minimal() +
  labs(title = "Per-Document Sentiment Ranking",   # >>> CHANGE: title
       x = "Document", y = "Net Sentiment Score (Bing)")

# most positive / most negative documents at a glance
head(doc_scores_full %>% arrange(desc(Net_Sentiment_Score)), 5)   # most positive
head(doc_scores_full %>% arrange(Net_Sentiment_Score), 5)         # most negative

# ==============================================================================
# END OF SCRIPT
# ==============================================================================
