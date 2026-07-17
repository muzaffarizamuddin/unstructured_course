### Text Analysis I: LDA
install.packages("topicmodels")
install.packages("tidytext")
install.packages("tidyr")
install.packages("dplyr")
install.packages("reshape2")
install.packages("wordcloud")
library(wordcloud)
library(tidytext)
library(topicmodels)
library(tidyr)
library(ggplot2)
library(dplyr)
library(tm)

mytext<- DirSource("D:/github/unstructured_course/Exam_Prep/News_Articles")
mycorpus<-VCorpus(mytext)

remove_footer_entirely <- content_transformer(function(x) {
   gsub("(?s)https.*$", "", x, perl = TRUE, ignore.case = TRUE)
})
docs <- tm_map(mycorpus, remove_footer_entirely)

toSpace <- content_transformer(function(x,pattern){gsub(pattern, " ", x)})
docs <- tm_map(docs, removeNumbers)
docs <- tm_map(docs, removePunctuation)
docs <- tm_map(docs, content_transformer(tolower))
docs <- tm_map(docs, removeWords, stopwords("english"))
docs <- tm_map(docs, removeWords, c("can","will","however","one","title","min",
	"read","including","also","new","may","mindich","said"))
docs <- tm_map(docs, toSpace, "–")
docs <- tm_map(docs, toSpace, "”")
docs <- tm_map(docs, toSpace, "“")
docs <- tm_map(docs, toSpace, "’")
docs <- tm_map(docs, toSpace, "‘")
docs <- tm_map(docs, toSpace, "-")

docs <- tm_map(docs, stripWhitespace)

inspect(docs[[1]])
inspect(docs[[2]])
inspect(docs[[3]])
inspect(docs[[4]])
inspect(docs[[5]])
inspect(docs[[6]])
inspect(docs[[7]])
inspect(docs[[43]])
inspect(docs[[80]])

dtm <- DocumentTermMatrix(docs)

#=====================================================================
# TASK 1: LDA ANALYSIS
#=====================================================================

ap_lda<-LDA(dtm,k=2,control=list(seed=1234)) #create two-topic LDA model ### must be in dtm format

ap_topics<-tidy(ap_lda,matrix="beta") #Extract the per-topic-per-word-probabilities

#Find terms that are most common within each topics
ap_top_terms <- ap_topics %>% group_by(topic) %>% top_n(30,beta) %>% ungroup () %>% arrange (topic, -beta)
ap_top_terms%>% mutate(term=reorder(term,beta))%>%
ggplot(aes(term,beta,fill=factor(topic)))+geom_col(show.legend=FALSE)+
facet_wrap(~topic,scales="free")+coord_flip() #visualize the above

#--------------plot wordcloud for each topic----------
# Filter data for Topic 1 and grab the top terms (e.g., top 100 terms for a dense cloud)
topic1_data <- ap_topics %>%
  filter(topic == 1) %>%
  top_n(100, beta)

# Generate Word Cloud for Topic 1
set.seed(1234) 
wordcloud(words = topic1_data$term, 
          freq = topic1_data$beta, 
          scale = c(3.5, 0.5),      # Max and min font size
          max.words = 100,          # Limit number of words
          random.order = FALSE,     # Plot largest words in the center
          rot.per = 0.35,           # % of vertical words
          colors = brewer.pal(8, "Dark2")) # Clean, professional color palette

# Filter data for Topic 2
topic2_data <- ap_topics %>%
  filter(topic == 2) %>%
  top_n(100, beta)

# Generate Word Cloud for Topic 2
set.seed(1234)
wordcloud(words = topic2_data$term, 
          freq = topic2_data$beta, 
          scale = c(3.5, 0.5), 
          max.words = 100, 
          random.order = FALSE, 
          rot.per = 0.35, 
          colors = brewer.pal(8, "Accent")) 

#--------------beta spread-----------------------

beta_spread <- ap_topics %>% mutate (topic=paste0("topic",topic)) %>% spread(topic,beta) %>%
filter (topic1>0.003 | topic2 >0.003) %>% mutate(log_ratio = log2(topic1/topic2))

beta_spread%>% mutate(term=reorder(term,log_ratio))%>%
ggplot(aes(term,log_ratio))+geom_col(show.legend=FALSE)+coord_flip()

tm_documents<-tidy(ap_lda,matrix="gamma") #Extract the per-document-per-topic-probabilities

tm_documents
print(n=80,tm_documents)

tm_documents %>% filter(topic==2)

tidy(dtm)%>%filter(document=="Science_Technology_NASA_Rolls_Out_Artemis_III_Moon_Rocket_Core_Stage.txt")%>%
	arrange(desc(count)) #Check the most common words in the document, eg document 6

#=====================================================================
# TASK 2: TEXT DATA CLUSTERING ANALYSIS
#=====================================================================

install.packages("proxy")
install.packages("dbscan")
install.packages("cluster")
install.packages("colorspace")

library(proxy)       # For calculating text-specific cosine distances
library(dbscan)      # For density-based HDBSCAN clustering
library(cluster)     # For generating partition clusplots
library(colorspace)  # For creating advanced visualization palettes

# --- Step 2: Build Term Matrix & Apply TF-IDF Weighting -------------
tdm<-dtm

# Apply TF-IDF Normalization to balance rare vs. hyper-frequent terms
tdm.tfidf <- weightTfIdf(tdm)

# Remove sparse terms to minimize matrix dimensionality and noise
tdm.tfidf <- removeSparseTerms(tdm.tfidf, 0.999)

# Convert the sparse DTM structure to a standard working matrix
tfidf.matrix <- as.matrix(tdm.tfidf)

# --- Step 3: Compute Cosine Distance Matrix -------------------------
# Cosine distance measures angle variations instead of raw Euclidean length, 
# making it highly appropriate for text representations.
dist.matrix <- dist(tfidf.matrix, method = "cosine") 

#-------------------------------------------------------------------------
# --- Elbow Method for Determining Optimal Clusters (K) for k means ------
#-------------------------------------------------------------------------

cost_df <- data.frame()

# Loop through potential cluster thresholds (1 to 20) to find the inflection point
for(i in 1:20){ 
  # Set a seed before each kmeans iteration for consistency
  set.seed(123)
  kmeans_test <- kmeans(x = tfidf.matrix, centers = i, nstart = 20, iter.max = 100) 
  cost_df <- rbind(cost_df, cbind(i, kmeans_test$tot.withinss)) 
}
names(cost_df) <- c("cluster", "cost")
dev.off() # resets plots
par(mar = c(5, 5, 4, 2)) #force standard margins

plot(cost_df$cluster, cost_df$cost, type = "b", pch = 19, xaxt = "n",
     xlab = "Number of Clusters (K)", 
     ylab = "Total Within-Cluster Cost",
     main = "Elbow Plot for Optimal K Selection",
     col = "darkblue", lwd = 2) 
axis(1, at = 1:20, labels = 1:20)
axis(2) # Force left vertical axis numbers to render

#-------------------------------------------------------------------------
# --- Construct all 3 models, use k=3 for k means based on elbow plot-----
#-------------------------------------------------------------------------

# Set the target cluster count to K = 3 
truth.K <- 3 
set.seed(123)

# 1. K-Means Algorithm (Distance-from-seed partitioning)
clustering.kmeans <- kmeans(tfidf.matrix, centers = truth.K, nstart = 20)

# 2. Hierarchical Clustering (Agglomerative bottom-up using Ward's linkage)
clustering.hierarchical <- hclust(dist.matrix, method = "ward.D2")

# 3. HDBSCAN Algorithm (Density-Based Clustering with Noise Isolation)
# Calibrated with minPts = 3 to fit tightly bound Cosine Distance thresholds
clustering.dbscan <- hdbscan(dist.matrix, minPts = 3)

# -------------------------------------------------------------------------------------
# --------------K-Means individual plots ---------------------------------------------
# ------------------------------------------------------------------------------------

# a) Silhouette Bivariate Partition Plot 
par(mar = c(5, 5, 4, 2)) 
clusplot(as.matrix(dist.matrix), 
         clustering.kmeans$cluster,
         color = TRUE, shade = TRUE, labels = 0, lines = 0,
         cex = 1.2, pch = 19,
         main = "K-Means Silhouette Cluster Partition", sub = "")

# a) ggplot2 Partition Mapping with Selective Label

install.packages("ggrepel")
library(ggplot2)
library(ggrepel)
library(dplyr)

# Project high-dimensional distances down to 2 dimensions for visual grid overlay
points_2d <- as.data.frame(cmdscale(dist.matrix, k = 2)) %>%
  rename(Dim1 = V1, Dim2 = V2) %>%
  mutate(
    DocName = rownames(tfidf.matrix),
    Cluster = as.factor(clustering.kmeans$cluster),
    # Strip away both prefixes and any trailing .txt extension cleanly
    CleanLabel = gsub("^Political_Views_|^Science_Technology_|\\.txt$", "", DocName, ignore.case = TRUE)
  )

# Calculate Euclidean distance of every document vector to its respective cluster center
centers <- clustering.kmeans$centers
points_2d$DistToCenter <- sapply(1:nrow(tfidf.matrix), function(i) {
  sum((tfidf.matrix[i, ] - centers[clustering.kmeans$cluster[i], ])^2)
})

# Filter down to top 3 highly central, representative labels per cluster
top3_docs <- points_2d %>%
  group_by(Cluster) %>%
  slice_min(order_by = DistToCenter, n = 3) %>%
  pull(DocName)

points_2d <- points_2d %>%
  mutate(DisplayLabel = ifelse(DocName %in% top3_docs, CleanLabel, ""))

# Render the polished ggplot2 K-Means Partition map
print(
  ggplot(points_2d, aes(x = Dim1, y = Dim2, color = Cluster)) +
    geom_point(size = 3, alpha = 0.6) +
    stat_ellipse(aes(fill = Cluster), geom = "polygon", alpha = 0.08, level = 0.95) +
    geom_text_repel(aes(label = DisplayLabel),
                    size = 3.8, fontface = "bold", box.padding = 0.6, point.padding = 0.4,
                    max.overlaps = Inf, show.legend = FALSE) +
    theme_minimal(base_size = 13) +
    labs(title = "K-Means Cluster Partition Plot",
         subtitle = "Displaying top 3 central articles per cluster",
         x = "Dimension 1", y = "Dimension 2") +
    theme(plot.title = element_text(face = "bold", hjust = 0.5),
          plot.subtitle = element_text(hjust = 0.5, color = "gray40"))
)

# -------------------------------------------------------------------------------------
# ----------------------------Hierarchical Dendrogram individual plot------------------
# ------------------------------------------------------------------------------------
install.packages("ape")
library(ape)

clean_matrix <- tfidf.matrix
rownames(clean_matrix) <- gsub("^Political_Views_|^Science_Technology_|\\.txt$", "", 
                                rownames(clean_matrix), ignore.case = TRUE)

clean_dist <- dist(clean_matrix, method = "cosine")
clean_hierarchical <- hclust(clean_dist, method = "ward.D2")
phylo_tree <- as.phylo(clean_hierarchical)

tree_clusters <- cutree(clean_hierarchical, k = truth.K)
# Map clear palette values: Cluster 1 = Coral, Cluster 2 = Skyblue, Cluster 3 = Gold/Dark
tree_colors <- c("coral2", "skyblue3", "goldenrod3")[tree_clusters]

par(mar = c(2, 2, 4, 2)) 
plot(phylo_tree, type = "fan", tip.color = tree_colors, edge.color = "gray40", 
     cex = 0.75, font = 2, main = "Hierarchical Clustering Structural Distribution")
legend("topleft", legend = c("Cluster 1 (Political)", "Cluster 2 (Artemis/Moon Travel)", "Cluster 3 (Administrative Science)"), 
       fill = c("coral2", "skyblue3", "goldenrod3"), bty = "n", cex = 0.9)


# -------------------------------------------------------------------------------------
# ----------------------------HDBSCAN Density Scatter individual Plot -----------------
# -------------------------------------------------------------------------------------
library(wordcloud)

# 1. Coordinate Setup
db_points <- as.data.frame(cmdscale(dist.matrix, k = 2))
db_points$Lbl <- gsub("^Political_Views_|^Science_Technology_|\\.txt$", "", rownames(tfidf.matrix), ignore.case = TRUE)
db_points$Cl  <- clustering.dbscan$cluster
palette_3pane <- c("darkgray", "coral2", "skyblue3", "goldenrod3", "palegreen4")

# 2. Render Main Scatter Plot
par(mar = c(5, 5, 4, 2)) 
plot(db_points$V1, db_points$V2, col = palette_3pane[db_points$Cl + 1L], 
     pch = 19, cex = 1.4, xlab = "Dimension 1", ylab = "Dimension 2",
     main = "HDBSCAN Core Density Matrix Scatter")

# 3. Pull Top 2 Central Documents Per Cluster (Skips Noise 0)
label_df <- data.frame()
for (i in 1:max(db_points$Cl)) {
  sub_cl <- subset(db_points, Cl == i)
  if (nrow(sub_cl) > 0) {
    sub_cl$Dist <- sqrt((sub_cl$V1 - mean(sub_cl$V1))^2 + (sub_cl$V2 - mean(sub_cl$V2))^2)
    label_df    <- rbind(label_df, head(sub_cl[order(sub_cl$Dist), ], 2))
  }
}
textplot(label_df$V1, label_df$V2, words = label_df$Lbl, 
         col = palette_3pane[label_df$Cl + 1L],
         new = FALSE, cex = 0.8, font = 2)

# 4. Matching Expanded Legend
legend("topleft", fill = palette_3pane, bty = "n", cex = 0.9,
       legend = c("Noise Outliers", "Core 1 (Artemis Accords)", "Core 2 (NASA Space news)", "Core 3 (Political and Military)", "Core 4 (Oil and business)"))

# 5. Print Complete Article Rosters per Cluster for Naming Analysis
cat("\n=========================================================\n")
cat("          HDBSCAN CLUSTER DOCUMENT ROSTERS               \n")
cat("=========================================================\n")

# Loop from Cluster 0 (Noise) up to your maximum detected cluster ID
for (i in 0:max(db_points$Cl)) {
  
  # Isolate documents matching the active cluster ID
  cluster_roster <- subset(db_points, Cl == i)
  
  # Create a clean header description for the console printout
  cluster_header <- if (i == 0) {
    "CLUSTER 0: UNASSIGNED NOISE OUTLIERS"
  } else {
    paste("CLUSTER", i, ": DENSE CORE THEMATIC HUB")
  }
  
  cat("\n---", cluster_header, paste0("(", nrow(cluster_roster), " Articles) --- \n"))
  
  # Print the cleaned document names as an ordered list if any exist
  if (nrow(cluster_roster) > 0) {
    print(sort(cluster_roster$Lbl))
  } else {
    cat("[No documents found]\n")
  }
}
cat("\n=========================================================\n")

# -------------------------------------------------------------------------------------
# --- Comparative Multi-Panel Plots ---------------------------------------------------
# -------------------------------------------------------------------------------------

# Establish a standardized 2D mapping layout from your shared distance profiles
points <- cmdscale(dist.matrix, k = 2)
x <- points[,1]
y <- points[,2]

# Define base structural tracking colors for panels A and B
main_colors <- c("coral2", "skyblue3", "goldenrod3")

# Initialize a clean, multi-panel graphics panel grid (1 row, 3 columns)
par(mfrow = c(1, 3), mar = c(4, 4, 4, 1)) 

# PANEL A: Named K-Means Partitioning
plot(x, y, main = 'K-Means Clustering (K=3)', 
     col = main_colors[clustering.kmeans$cluster], pch = 19, cex = 1.4,
     xlab = 'Dimension 1', ylab = 'Dimension 2')
legend("topleft", fill = main_colors, bty = "n", cex = 0.9,
       legend = c("Cluster 1: Global Politics", 
                  "Cluster 2: Space Exploration", 
                  "Cluster 3: Anomalous Outlier"))

# PANEL B: Named Hierarchical Tree Branches
h_assignments <- cutree(clustering.hierarchical, k = truth.K)
plot(x, y, main = 'Hierarchical Clustering (K=3)', 
     col = main_colors[h_assignments], pch = 19, cex = 1.4,
     xlab = 'Dimension 1', ylab = '')
legend("topleft", fill = main_colors, bty = "n", cex = 0.9,
       legend = c("Cluster 1: Hard Geopolitics", 
                  "Cluster 2: Artemis Lunar Missions", 
                  "Cluster 3: Agency Space Science"))

# PANEL C: Named HDBSCAN Density Cores (5-Group Layout)
db_assigned <- clustering.dbscan$cluster
palette_5group <- c("darkgray", "coral2", "skyblue3", "goldenrod3", "palegreen4")

plot(x, y, main = 'HDBSCAN Density Clustering', 
     col = palette_5group[db_assigned + 1L], pch = 19, cex = 1.4,
     xlab = 'Dimension 1', ylab = '')
legend("topleft", fill = palette_5group, bty = "n", cex = 0.9,
       legend = c("Noise: Unassigned Outliers", 
                  "Core 1: Artemis Accords", 
                  "Core 2: NASA Space News", 
                  "Core 3: Political and Military", 
                  "Core 4: Oil and Business"))

# Reset plotting window back to normal single-pane layout
par(mfrow = c(1, 1))

# -------------------------------------------------------------------------------------
# --- Text clustering: Print Descriptive Document Assignment Matrices -----------------
# -------------------------------------------------------------------------------------

cat("\n=== K-Means Clustering Layout ===\n")
print(table(clustering.kmeans$cluster)) 

cat("\n=== Hierarchical Linkage Layout ===\n")
print(table(h_assignments)) 

cat("\n=== HDBSCAN Noise-Isolating Layout (0 = Unassigned Noise) ===\n")
print(table(clustering.dbscan$cluster))

 