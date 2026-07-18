#Muzaffar Izamuddin bin Daud
#P166246



# ------------------------------------------------------------------------
# 0. LIBRARIES
# ------------------------------------------------------------------------
# install.packages(c("tm","topicmodels","tidytext","tidyr","dplyr","ggplot2",
#                     "wordcloud","RColorBrewer","proxy","dbscan","cluster",
#                     "colorspace"))

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

mytext   <- DirSource("C:/Users/PC03/Desktop/github/unstructured_course/Final_Exam/TextData")
mycorpus <- VCorpus(mytext)

length(mycorpus)          # ~102 documents
mycorpus[[1]]$meta$id     # filename of first document

# ==============================================================================
# 2. DATA CLEANING
# ==============================================================================

toSpace <- content_transformer(function(x, pattern) { gsub(pattern, " ", x) })

docs <- tm_map(mycorpus, removeNumbers)
docs <- tm_map(docs, removePunctuation)
docs <- tm_map(docs, content_transformer(tolower))
docs <- tm_map(docs, removeWords, stopwords("english"))
docs <- tm_map(docs, toSpace, "–")
docs <- tm_map(docs, toSpace, "—")
docs <- tm_map(docs, toSpace, "”")
docs <- tm_map(docs, toSpace, "“")
docs <- tm_map(docs, toSpace, "’")
docs <- tm_map(docs, toSpace, "‘")
docs <- tm_map(docs, toSpace, "-")
docs <- tm_map(docs, removeWords, c("can","will","however","one","title","including","also","new","may","said", "wwwfreepikcom"))
docs <- tm_map(docs, stripWhitespace)

# --- check the corpus---
all_text <- unname(sapply(docs, as.character))
head(all_text)
inspect(docs[[1]])
inspect(docs[[2]])
as.character(docs[[1]])
for (i in 1:5) {
  print(as.character(docs[[i]]))
}

#remove single words
docs <- tm_map(docs, content_transformer(function(x) gsub("\\b[[:alpha:]]\\b", " ", x))) #remove single letter
docs <- tm_map(docs, stripWhitespace)
docs_1<-docs #save backup

library(textstem)
#we then use textstem library to lemmatize the strings, a tokenization process
docs<- tm_map(docs,content_transformer(lemmatize_strings))

#check the lemmaitized strings
for(i in 1:10){
	print(as.character(docs_1[[i]]))
}

# ==============================================================================
# 4. DOCUMENT-TERM MATRIX
# ==============================================================================

dtm <- DocumentTermMatrix(docs)
inspect(dtm)


# ==============================================================================
# TASK A: LDA (TOPIC MODELLING)
# ==============================================================================

LDA_K <- 3   # 3 topics as per question

ap_lda <- LDA(dtm, k = LDA_K, control = list(seed = 1234))

install.packages("tidytext")
install.packages("dplyr")
library(tidytext)
library(dplyr)

# 1. Point R directly to your clean library again
fresh_lib <- "C:/Users/PC03/AppData/Local/R/win-library/exam_clean"
.libPaths(c(fresh_lib, .libPaths()))
# 2. Force load the correct rlang explicitly from the clean folder
library(rlang, lib.loc = fresh_lib)
# 3. Force load tidytext from the clean folder
library(tidytext, lib.loc = fresh_lib)
# 4. Now run the extraction
ap_topics <- tidytext:::tidy.LDA(ap_lda, matrix = "beta")
# ---- per-topic-per-word probabilities (beta) ----
ap_topics <- tidytext:::tidy.LDA(ap_lda, matrix = "beta")


# 1. Extract the raw log-probabilities matrix (estimated beta values)
raw_beta <- ap_lda@beta

# 2. Get the terms (words) and convert log-probabilities back to standard probabilities
terms_list <- ap_lda@terms
beta_probs <- exp(raw_beta) # LDA stores beta as log-probabilities, so exp() converts them back

# 3. Rebuild the tidy data frame structure manually
ap_topics <- data.frame(
  topic = rep(1:nrow(beta_probs), each = ncol(beta_probs)),
  term  = rep(terms_list, times = nrow(beta_probs)),
  beta  = as.vector(t(beta_probs)),
  stringsAsFactors = FALSE
)

# 4. Check the result
head(ap_topics)

top_words <- ap_topics[ap_topics$beta > 0.01, ]
sorted_topics <- ap_topics[order(-ap_topics$beta), ]
top_10 <- head(sorted_topics, 10)

ap_top_terms <- ap_topics %>%
  group_by(topic) %>%
  top_n(30, beta) %>%
  ungroup() %>%
  arrange(topic, -beta)

ap_top_terms %>%
  mutate(term = reorder(term, beta)) %>%
  ggplot(aes(term, beta, fill = factor(topic))) +
  geom_col(show.legend = FALSE) +
  facet_wrap(~topic, scales = "free") +
  coord_flip()


# ---- wordcloud per topic ----
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

# most common words in one specific (real) document from this folder
tidy(dtm) %>%
  filter(document == "Science_Technology_NASA_Rolls_Out_Artemis_III_Moon_Rocket_Core_Stage.txt") %>%
  arrange(desc(count))


# ==============================================================================
# TASK B: TEXT DATA CLUSTERING
# ==============================================================================

# ------------------------------------------------------------------------
# Step 1: TF-IDF weighting + cosine distance matrix
# ------------------------------------------------------------------------
tdm <- dtm
tdm.tfidf <- weightTfIdf(tdm)
tdm.tfidf <- removeSparseTerms(tdm.tfidf, 0.999)

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
# the elbow on this folder sits around K = 3, matching the 3 natural themes
# (politics, NASA/Artemis space news, and general tech)

# ------------------------------------------------------------------------
# Step 3: SET NUMBER OF CLUSTERS + LABELS
# ------------------------------------------------------------------------
truth.K <- 3

# cleaned-up document names for readable roster printouts and plot labels
doc_names       <- rownames(tfidf.matrix)
doc_names_clean <- gsub("^Political_Views_|^Science_Technology_|\\.txt$", "",
                         doc_names, ignore.case = TRUE)

# NOTE: k-means and hierarchical clustering do NOT have to agree on exactly
# which articles end up together, so each gets its OWN label set below --
# these are the labels that made sense the last time this exact folder was
# run through this exact pipeline. Always re-check against the roster
# printout in Step 4 before trusting them (cluster numbering can shift if
# the seed, package version, or article set changes).
KMEANS_LABELS <- c("Cluster 1: Global Politics",
                    "Cluster 2: Space Exploration",
                    "Cluster 3: Anomalous Outlier")

HIER_LABELS   <- c("Cluster 1: Hard Geopolitics",
                    "Cluster 2: Artemis Lunar Missions",
                    "Cluster 3: Agency Space Science")

CLUSTER_COLORS <- c("coral2", "skyblue3", "goldenrod3")   # one colour per cluster (truth.K = 3)

set.seed(123)
clustering.kmeans       <- kmeans(tfidf.matrix, centers = truth.K, nstart = 20)
clustering.hierarchical <- hclust(dist.matrix, method = "ward.D2")
h_assignments           <- cutree(clustering.hierarchical, k = truth.K)

# HDBSCAN finds its own number of clusters + noise (cluster 0) -- on this
# folder it typically resolves into 4 dense "cores" plus noise
clustering.dbscan <- hdbscan(dist.matrix, minPts = 3)

DB_LABELS <- c("Noise: Unassigned Outliers",
               "Core 1: Artemis Accords",
               "Core 2: NASA Space News",
               "Core 3: Political and Military",
               "Core 4: Oil and Business")
DB_COLORS <- c("darkgray", "coral2", "skyblue3", "goldenrod3", "palegreen4")

# ------------------------------------------------------------------------
# Step 4: PRINT CLUSTER ROSTERS -- confirm the labels above actually match
# ------------------------------------------------------------------------
cat("\n=== K-MEANS CLUSTER ROSTERS ===\n")
for (i in 1:truth.K) {
  cat("\n---", KMEANS_LABELS[i], "---\n")
  print(sort(doc_names_clean[clustering.kmeans$cluster == i]))
}

cat("\n=== HIERARCHICAL CLUSTER ROSTERS ===\n")
for (i in 1:truth.K) {
  cat("\n---", HIER_LABELS[i], "---\n")
  print(sort(doc_names_clean[h_assignments == i]))
}

cat("\n=== HDBSCAN CLUSTER ROSTERS (0 = noise/unassigned) ===\n")
for (i in 0:max(clustering.dbscan$cluster)) {
  cat("\n---", DB_LABELS[i + 1], "---\n")
  print(sort(doc_names_clean[clustering.dbscan$cluster == i]))
}

# ------------------------------------------------------------------------
# Step 5: PLOTS -- using the labels/colours set in Step 3
# ------------------------------------------------------------------------

points <- cmdscale(dist.matrix, k = 2)

# a) K-Means -- basic silhouette-style partition plot
clusplot(as.matrix(dist.matrix), clustering.kmeans$cluster,
         color = TRUE, shade = TRUE, labels = 0, lines = 0,
         cex = 1.2, pch = 19, main = "K-Means Cluster Partition", sub = "")

# b) K-Means -- 2D scatter with labelled legend
plot(points, main = 'K-Means Clustering', col = CLUSTER_COLORS[clustering.kmeans$cluster],
     pch = 19, cex = 1.4, xlab = 'Dimension 1', ylab = 'Dimension 2')
legend("topleft", fill = CLUSTER_COLORS, bty = "n", cex = 0.9, legend = KMEANS_LABELS)

# c) Hierarchical -- dendrogram
plot(clustering.hierarchical, main = "Hierarchical Clustering Dendrogram",
     xlab = "", sub = "", cex = 0.6, labels = doc_names_clean)
rect.hclust(clustering.hierarchical, k = truth.K, border = CLUSTER_COLORS)

# d) Hierarchical -- 2D scatter using its own labels
plot(points, main = 'Hierarchical Clustering', col = CLUSTER_COLORS[h_assignments],
     pch = 19, cex = 1.4, xlab = 'Dimension 1', ylab = 'Dimension 2')
legend("topleft", fill = CLUSTER_COLORS, bty = "n", cex = 0.9, legend = HIER_LABELS)

# e) HDBSCAN -- 2D scatter (noise = cluster 0, shown in grey)
plot(points, main = 'HDBSCAN Density Clustering',
     col = DB_COLORS[clustering.dbscan$cluster + 1L], pch = 19, cex = 1.4,
     xlab = 'Dimension 1', ylab = 'Dimension 2')
legend("topleft", fill = DB_COLORS, bty = "n", cex = 0.9, legend = DB_LABELS)

# f) Side-by-side comparison panel (K-Means / Hierarchical / HDBSCAN)
par(mfrow = c(1, 3), mar = c(4, 4, 4, 1))

plot(points, main = 'K-Means (K=3)', col = CLUSTER_COLORS[clustering.kmeans$cluster],
     pch = 19, cex = 1.4, xlab = 'Dim 1', ylab = 'Dim 2')
legend("topleft", fill = CLUSTER_COLORS, bty = "n", cex = 0.7, legend = KMEANS_LABELS)

plot(points, main = 'Hierarchical (K=3)', col = CLUSTER_COLORS[h_assignments],
     pch = 19, cex = 1.4, xlab = 'Dim 1', ylab = '')
legend("topleft", fill = CLUSTER_COLORS, bty = "n", cex = 0.7, legend = HIER_LABELS)

plot(points, main = 'HDBSCAN Density', col = DB_COLORS[clustering.dbscan$cluster + 1L],
     pch = 19, cex = 1.4, xlab = 'Dim 1', ylab = '')
legend("topleft", fill = DB_COLORS, bty = "n", cex = 0.7, legend = DB_LABELS)

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
