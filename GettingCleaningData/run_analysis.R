library(data.table)

# Loading test and training subjects.
sub_tst <- fread(file.path(getwd(), "UCI HAR Dataset/test/subject_test.txt"))
sub_train <- fread(file.path(getwd(), "UCI HAR Dataset/train/subject_train.txt"))

# Loading test and training activity.
ac_tst <- fread(file.path(getwd(), "UCI HAR Dataset/test/y_test.txt"))
ac_train <- fread(file.path(getwd(), "UCI HAR Dataset/train/y_train.txt"))

# Loading test and training data files.
# I had some problems in reading using fread(), R Studio crashed due to high 
# system load (maybe the problem is the data size?), had to do a workaround
# using tables.
dt_tst <- data.table(read.table(file.path(getwd(), "UCI HAR Dataset/test/x_test.txt")))
dt_train <- data.table(read.table(file.path(getwd(), "UCI HAR Dataset/train/x_train.txt")))

# Merge test and training subject, activity and data sets.
tt_sub <- rbind(sub_tst, sub_train)
tt_ac <- rbind(ac_tst, ac_train)
final_data <- rbind(dt_tst, dt_train)

# Put descriptive names.
setnames(tt_sub, "V1", "subject_id")
setnames(tt_ac, "V1", "ac_id")

# Merge activity and subject data frames.
tt_newcolumns <- cbind(tt_ac, tt_sub)

# Merge earlier two columns in the final data set.
final_data <- cbind(tt_newcolumns, final_data)

# Getting the column names to extract measurements.
colnames <- fread(file.path(getwd(), "UCI HAR Dataset/features.txt"))
setnames(colnames, names(colnames), c("var_id", "var_label"))

# Filtering for std and mean measurements (ugly code, but it works!)
var_filter <- colnames[grepl("mean\\(\\)|std\\(\\)", var_label)]
var_filter$column_name <- var_filter[, paste("V", var_id, sep="")]
subset_data <- final_data[, c("ac_id", "subject_id", var_filter$column_name), with=FALSE]

# Putting descriptive names to the selected columns.
setnames(subset_data, names(subset_data), c("ac_id", "subject_id", t(var_filter[, var_label])))

# Loading Activity names.
ac_names <- fread(file.path(getwd(), "UCI HAR Dataset/activity_labels.txt"))
setnames(ac_names, names(ac_names), c("ac_id", "ac_name"))
subset_data <- merge(subset_data, ac_names, by="ac_id", all.x=TRUE)
setkey(subset_data, subject_id, ac_id, ac_name)

# Cleaning data.
clean_data <- aggregate(subset_data, by = list(subject_id=subset_data$subject_id, ac_id=subset_data$ac_id, ac_name=subset_data$ac_name), mean)
write.table(clean_data, file="data.txt", row.names=FALSE)
