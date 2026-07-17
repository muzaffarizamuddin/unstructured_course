# ==============================================================================
# MODEL SCRIPT: TEXT DATA ANALYSIS -- LDA + TEXT CLUSTERING + WORDCLOUD
# Course: STQD6114 | Copy-paste template for the final exam
#
# HOW TO USE THIS FILE:
#   Every place you might need to edit for a different exam question is
#   marked with a line starting "# >>> CHANGE:" -- search for ">>> CHANGE"
#   to jump between all the settings you may need to touch.
#
# WORKFLOW: DirSource folder -> VCorpus -> clean -> DTM -> LDA -> wordcloud
#           -> TF-IDF -> distance matrix -> cluster (kmeans/hclust/HDBSCAN)
#           -> label + plot clusters
# ==============================================================================

# ------------------------------------------------------------------------
# 0. LIBRARIES
# ------------------------------------------------------------------------
# install.packages(c("tm","topicmodels","tidytext","tidyr","dplyr","ggplot2",
#                     "wordcloud","RColorBrewer","proxy","dbscan","cluster",
#                     "colorspace","ggrepel","ape"))

library(tm)
library(topicmodels)
library(tidytext)
library(tidyr)
library(dplyr)
library(ggplot2)
library(wordcloud)
library(RColorBrewer)
library(proxy)       # cosine distance
library(dbscan)      # HDBSCAN
library(cluster)     # clusplot
library(colorspace)  # multi-panel colour palettes


# ==============================================================================
# 1. LOAD DATA -- DirSource (folder of .txt files) -> VCorpus
# ==============================================================================

# >>> CHANGE: point this at the folder of documents given in the exam
mytext   <- DirSource("C:/path/to/your/Data_Folder")
mycorpus <- VCorpus(mytext)

length(mycorpus)          # sanity check: number of documents read in
mycorpus[[1]]$meta$id     # sanity check: filename of first document


# OPTIONAL: if the raw files contain a footer/boilerplate you want stripped
# BEFORE the standard cleaning (e.g. a trailing URL, "Read more at ..."),
# uncomment and adjust the regex below.
# >>> CHANGE: only needed if your files have a repeated footer to strip
# remove_footer_entirely <- content_transformer(function(x) {
#   gsub("(?s)https.*$", "", x, perl = TRUE, ignore.case = TRUE)
# })
# mycorpus <- tm_map(mycorpus, remove_footer_entirely)


# ==============================================================================
# 2. DATA CLEANING
# ==============================================================================

toSpace <- content_transformer(function(x, pattern) { gsub(pattern, " ", x) })

docs <- tm_map(mycorpus, removeNumbers)
docs <- tm_map(docs, removePunctuation)
docs <- tm_map(docs, content_transformer(tolower))
docs <- tm_map(docs, removeWords, stopwords("english"))

# >>> CHANGE: add/remove your own custom stopwords here based on what shows
#             up as noise when you inspect the corpus below (step 3)
docs <- tm_map(docs, removeWords, c("can","will","however","one","title","min",
	"read","including","also","new","may","said"))

# curly quotes / dashes that removePunctuation does not always catch cleanly
docs <- tm_map(docs, toSpace, "–")
docs <- tm_map(docs, toSpace, "”")
docs <- tm_map(docs, toSpace, "“")
docs <- tm_map(docs, toSpace, "’")
docs <- tm_map(docs, toSpace, "‘")
docs <- tm_map(docs, toSpace, "-")

docs <- tm_map(docs, stripWhitespace)


# ==============================================================================
# 3. INSPECT CORPUS (check cleaning worked, both doc-by-doc AND as a whole)
# ==============================================================================

# --- a few documents individually ---
inspect(docs[[1]])
inspect(docs[[2]])
as.character(docs[[1]])

for (i in 1:5) {
  print(as.character(docs[[i]]))
}

# --- the WHOLE corpus at once ---
all_text <- unname(sapply(docs, as.character))
head(all_text)

# scan for any leftover non-alphanumeric characters across ALL documents
# (if this shows something like "…" or "—", add it to the toSpace calls above
#  and re-run the cleaning block)
leftover_chars <- unique(unlist(regmatches(all_text, gregexpr("[^a-z0-9 ]", all_text))))
sort(leftover_chars)


# ==============================================================================
# 4. DOCUMENT-TERM MATRIX
# ==============================================================================

dtm <- DocumentTermMatrix(docs)

# OPTIONAL stricter version (uncomment if the exam asks to control word
# length / global frequency bounds):
# >>> CHANGE: adjust wordLengths / bounds if the question asks for it
# dtm <- DocumentTermMatrix(docs, control = list(wordLengths = c(2, 20),
#                                                 bounds = list(global = c(1, 30))))

inspect(dtm)


# ==============================================================================
# TASK A: LDA (TOPIC MODELLING)
# ==============================================================================

# >>> CHANGE: number of topics to extract
LDA_K <- 2

ap_lda <- LDA(dtm, k = LDA_K, control = list(seed = 1234))

# ---- per-topic-per-word probabilities (beta) ----
ap_topics <- tidy(ap_lda, matrix = "beta")

# >>> CHANGE: how many top words per topic to show/plot
ap_top_terms <- ap_topics %>%
  group_by(topic) %>%
  top_n(15, beta) %>%
  ungroup() %>%
  arrange(topic, -beta)

ap_top_terms %>%
  mutate(term = reorder(term, beta)) %>%
  ggplot(aes(term, beta, fill = factor(topic))) +
  geom_col(show.legend = FALSE) +
  facet_wrap(~topic, scales = "free") +
  coord_flip()

# ---- wordcloud per topic ----
# >>> CHANGE: repeat this block once per topic if LDA_K > 2
#             (just change the `filter(topic == X)` and the `colors =`)
topic1_data <- ap_topics %>% filter(topic == 1) %>% top_n(100, beta)
set.seed(1234)
wordcloud(words = topic1_data$term, freq = topic1_data$beta,
          scale = c(3.5, 0.5), max.words = 100,
          random.order = FALSE, rot.per = 0.35,
          colors = brewer.pal(8, "Dark2"))

topic2_data <- ap_topics %>% filter(topic == 2) %>% top_n(100, beta)
set.seed(1234)
wordcloud(words = topic2_data$term, freq = topic2_data$beta,
          scale = c(3.5, 0.5), max.words = 100,
          random.order = FALSE, rot.per = 0.35,
          colors = brewer.pal(8, "Accent"))

# ---- beta spread: terms with biggest difference between topic 1 vs 2 ----
# NOTE: this specific log-ratio approach only works cleanly for LDA_K = 2
# >>> CHANGE: the 0.003 threshold controls how many terms are shown
beta_spread <- ap_topics %>%
  mutate(topic = paste0("topic", topic)) %>%
  spread(topic, beta) %>%
  filter(topic1 > 0.003 | topic2 > 0.003) %>%
  mutate(log_ratio = log2(topic1 / topic2))

beta_spread %>%
  mutate(term = reorder(term, log_ratio)) %>%
  ggplot(aes(term, log_ratio)) +
  geom_col(show.legend = FALSE) +
  coord_flip()

# ---- per-document-per-topic probabilities (gamma) ----
tm_documents <- tidy(ap_lda, matrix = "gamma")
print(n = 80, tm_documents)

tm_documents %>% filter(topic == 2) %>% arrange(desc(gamma))

# check most common words in one specific document
# >>> CHANGE: set this to a real filename from your corpus (see step 1 sanity check)
tidy(dtm) %>%
  filter(document == "example_filename.txt") %>%
  arrange(desc(count))


# ==============================================================================
# TASK B: TEXT DATA CLUSTERING
# ==============================================================================

# ------------------------------------------------------------------------
# Step 1: TF-IDF weighting + cosine distance matrix
# ------------------------------------------------------------------------
tdm <- dtm
tdm.tfidf <- weightTfIdf(tdm)
tdm.tfidf <- removeSparseTerms(tdm.tfidf, 0.999)   # >>> CHANGE: sparsity threshold if needed

tfidf.matrix <- as.matrix(tdm.tfidf)
dist.matrix  <- dist(tfidf.matrix, method = "cosine")

# ------------------------------------------------------------------------
# Step 2: Elbow method to help decide K for k-means
# ------------------------------------------------------------------------
cost_df <- data.frame()
for (i in 1:20) {
  set.seed(123)
  kmeans_test <- kmeans(x = tfidf.matrix, centers = i, nstart = 20, iter.max = 100)
  cost_df <- rbind(cost_df, cbind(i, kmeans_test$tot.withinss))
}
names(cost_df) <- c("cluster", "cost")

plot(cost_df$cluster, cost_df$cost, type = "b", pch = 19, xaxt = "n",
     xlab = "Number of Clusters (K)", ylab = "Total Within-Cluster Cost",
     main = "Elbow Plot for Optimal K Selection", col = "darkblue", lwd = 2)
axis(1, at = 1:20, labels = 1:20)

# ------------------------------------------------------------------------
# Step 3: SET NUMBER OF CLUSTERS + LABELS
# ------------------------------------------------------------------------
# >>> CHANGE: set truth.K based on the elbow plot above (this run uses 3)
truth.K <- 3

# >>> CHANGE: CLUSTER_LABELS must have exactly `truth.K` entries, in the
#             SAME ORDER as the cluster numbers 1, 2, 3, ... produced below.
#             Leave as generic placeholders first, run the "cluster roster"
#             printout further down to see what's actually IN each cluster,
#             THEN come back and rename these labels to match.
CLUSTER_LABELS <- c("Cluster 1: TODO - name me",
                     "Cluster 2: TODO - name me",
                     "Cluster 3: TODO - name me")

CLUSTER_COLORS <- c("coral2", "skyblue3", "goldenrod3")   # >>> CHANGE: needs truth.K colours

set.seed(123)
clustering.kmeans     <- kmeans(tfidf.matrix, centers = truth.K, nstart = 20)
clustering.hierarchical <- hclust(dist.matrix, method = "ward.D2")
h_assignments         <- cutree(clustering.hierarchical, k = truth.K)

# HDBSCAN does NOT take a K -- it finds its own number of clusters + noise (cluster 0)
# >>> CHANGE: minPts controls how "dense" a group must be to count as a cluster
clustering.dbscan <- hdbscan(dist.matrix, minPts = 3)

# ------------------------------------------------------------------------
# Step 4: PRINT CLUSTER ROSTERS -- read this BEFORE writing your labels above
# ------------------------------------------------------------------------
doc_names <- rownames(tfidf.matrix)

cat("\n=== K-MEANS CLUSTER ROSTERS (use this to decide CLUSTER_LABELS) ===\n")
for (i in 1:truth.K) {
  cat("\n---", CLUSTER_LABELS[i], "---\n")
  print(doc_names[clustering.kmeans$cluster == i])
}

cat("\n=== HIERARCHICAL CLUSTER ROSTERS ===\n")
for (i in 1:truth.K) {
  cat("\n--- Cluster", i, "---\n")
  print(doc_names[h_assignments == i])
}

cat("\n=== HDBSCAN CLUSTER ROSTERS (0 = noise/unassigned) ===\n")
for (i in 0:max(clustering.dbscan$cluster)) {
  cat("\n--- HDBSCAN cluster", i, "---\n")
  print(doc_names[clustering.dbscan$cluster == i])
}

# ------------------------------------------------------------------------
# Step 5: PLOTS -- using the labels/colours set in Step 3
# ------------------------------------------------------------------------

# a) K-Means -- basic silhouette-style partition plot
clusplot(as.matrix(dist.matrix), clustering.kmeans$cluster,
         color = TRUE, shade = TRUE, labels = 0, lines = 0,
         cex = 1.2, pch = 19, main = "K-Means Cluster Partition", sub = "")

# b) K-Means -- ggplot2 view with labelled legend
points <- cmdscale(dist.matrix, k = 2)
plot(points, main = 'K-Means Clustering', col = CLUSTER_COLORS[clustering.kmeans$cluster],
     pch = 19, cex = 1.4, xlab = 'Dimension 1', ylab = 'Dimension 2')
legend("topleft", fill = CLUSTER_COLORS, bty = "n", cex = 0.9,
       legend = CLUSTER_LABELS)     # <-- labels plugged in here

# c) Hierarchical -- dendrogram
plot(clustering.hierarchical, main = "Hierarchical Clustering Dendrogram",
     xlab = "", sub = "", cex = 0.7)
rect.hclust(clustering.hierarchical, k = truth.K, border = CLUSTER_COLORS)

# d) Hierarchical -- 2D scatter using the same labels
plot(points, main = 'Hierarchical Clustering', col = CLUSTER_COLORS[h_assignments],
     pch = 19, cex = 1.4, xlab = 'Dimension 1', ylab = 'Dimension 2')
legend("topleft", fill = CLUSTER_COLORS, bty = "n", cex = 0.9,
       legend = CLUSTER_LABELS)     # <-- reuse the SAME labels (or edit if hclust groups differ)

# e) HDBSCAN -- 2D scatter (noise = cluster 0, shown in grey)
# >>> CHANGE: DB_LABELS length must be (max cluster id + 1) to include "Noise" at index 1
DB_LABELS <- c("Noise / Unassigned", "HDBSCAN Cluster 1", "HDBSCAN Cluster 2", "HDBSCAN Cluster 3")
DB_COLORS <- c("darkgray", "coral2", "skyblue3", "goldenrod3")

plot(points, main = 'HDBSCAN Density Clustering',
     col = DB_COLORS[clustering.dbscan$cluster + 1L], pch = 19, cex = 1.4,
     xlab = 'Dimension 1', ylab = 'Dimension 2')
legend("topleft", fill = DB_COLORS, bty = "n", cex = 0.9, legend = DB_LABELS)

# f) Side-by-side comparison panel (K-Means / Hierarchical / HDBSCAN)
par(mfrow = c(1, 3), mar = c(4, 4, 4, 1))

plot(points, main = 'K-Means (K=3)', col = CLUSTER_COLORS[clustering.kmeans$cluster],
     pch = 19, cex = 1.4, xlab = 'Dim 1', ylab = 'Dim 2')
legend("topleft", fill = CLUSTER_COLORS, bty = "n", cex = 0.8, legend = CLUSTER_LABELS)

plot(points, main = 'Hierarchical (K=3)', col = CLUSTER_COLORS[h_assignments],
     pch = 19, cex = 1.4, xlab = 'Dim 1', ylab = '')
legend("topleft", fill = CLUSTER_COLORS, bty = "n", cex = 0.8, legend = CLUSTER_LABELS)

plot(points, main = 'HDBSCAN Density', col = DB_COLORS[clustering.dbscan$cluster + 1L],
     pch = 19, cex = 1.4, xlab = 'Dim 1', ylab = '')
legend("topleft", fill = DB_COLORS, bty = "n", cex = 0.8, legend = DB_LABELS)

par(mfrow = c(1, 1))    # reset plotting layout back to normal

# ------------------------------------------------------------------------
# Step 6: Summary tables
# ------------------------------------------------------------------------
cat("\n=== K-Means cluster sizes ===\n"); print(table(clustering.kmeans$cluster))
cat("\n=== Hierarchical cluster sizes ===\n"); print(table(h_assignments))
cat("\n=== HDBSCAN cluster sizes (0 = noise) ===\n"); print(table(clustering.dbscan$cluster))

# ==============================================================================
# END OF SCRIPT
# ==============================================================================
