# Check if packages are installed
list.of.packages <- c("plyr", "dplyr", "LaF", "ffbase")
new.packages <- list.of.packages[
    !(list.of.packages %in% installed.packages()[,"Package"])
]
if(length(new.packages)) install.packages(new.packages)

# Include packages
library(plyr)
library(dplyr)
library(LaF)
library(ffbase)

# Get actual Working Directory
script.dir <- dirname(sys.frame(1)$ofile)
setwd(script.dir)

# Data URL
urlFile <- paste(c(
    'https://d396qusza40orc.cloudfront.net/',
    'getdata%2Fprojectfiles%2FUCI%20HAR%20Dataset.zip'
))

# Check if data file exists, if not the case download it.
if (!file.exists('data/activity.zip')) {
    if (!file.exists('data')) {
        dir.create('data')
    }
    download.file(urlFile, 'data/activity.zip', method = "curl")
}

# Check if data exists, if not the case unzip the file.
if (!file.exists('UCI HAR Dataset')) {
    unzip('data/activity.zip')
}

# 1. Merges the training and the test sets to create one data set.
if (!exists('data_activity')) {

    # Data info
    features <- 561
    column_widths_fwf <- rep(c(16), features)
    column_types_fwf <- rep(c('numeric'), features)
    
    # Get Features Names
    if (!exists('data_features')) {
        data_features <- read.csv(
            'UCI HAR Dataset/features.txt',
            header = FALSE,
            sep = " "
        )
        colnames(data_features) <- c('id', 'feature')
    }
    
    # Get Labels
    if (!exists('data_labels')) {
        data_labels <- read.csv(
            'UCI HAR Dataset/activity_labels.txt',
            header = FALSE,
            sep = " "
        )
        colnames(data_labels) <- c('id', 'label')
    }
    
    # Get Activity Train X Data
    if (!exists('data_activity_train')) {
        data_activity_train_fwf <- laf_open_fwf(
            'UCI HAR Dataset/train/X_train.txt',
            column_widths = column_widths_fwf,
            column_types = column_types_fwf
        )
        data_activity_train_read <- laf_to_ffdf(data_activity_train_fwf)
        data_activity_train <- as.data.frame(data_activity_train_read)
        remove(data_activity_train_fwf, data_activity_train_read)
        
        # 4. Appropriately labels the data set with descriptive variable names.
        colnames(data_activity_train) <- data_features$feature
    }
    
    # Get Activity Train y labels
    if (!exists('data_activity_train_labels')) {
        data_activity_train_labels <- read.fwf(
            'UCI HAR Dataset/train/y_train.txt',
            widths = c(1)
        )
        colnames(data_activity_train_labels) <- c('activity')
    }
    
    # Get Activity Train subject
    if (!exists('data_activity_train_subject')) {
        data_activity_train_subject <- read.fwf(
            'UCI HAR Dataset/train/subject_train.txt',
            widths = c(1)
        )
        colnames(data_activity_train_subject) <- c('subject')
    }
    
    # Get Activity Test X Data
    if (!exists('data_activity_test')) {
        data_activity_test_fwf <- laf_open_fwf(
            'UCI HAR Dataset/test/X_test.txt',
            column_widths = column_widths_fwf,
            column_types = column_types_fwf
        )
        data_activity_test_read <- laf_to_ffdf(data_activity_test_fwf)
        data_activity_test <- as.data.frame(data_activity_test_read)
        remove(data_activity_test_fwf, data_activity_test_read)
        
        # 4. Appropriately labels the data set with descriptive variable names.
        colnames(data_activity_test) <- data_features$feature
    }
    
    # Get Activity Test y labels
    if (!exists('data_activity_test_labels')) {
        data_activity_test_labels <- read.fwf(
            'UCI HAR Dataset/test/y_test.txt',
            widths = c(1)
        )
        colnames(data_activity_test_labels) <- c('activity')
    }
    
    # Get Activity Test subject
    if (!exists('data_activity_test_subject')) {
        data_activity_test_subject <- read.fwf(
            'UCI HAR Dataset/test/subject_test.txt',
            widths = c(1)
        )
        colnames(data_activity_test_subject) <- c('subject')
    }
    
    # Merge Data
    data_activity <- data.frame(
        rbind(
            cbind(
                data_activity_train,
                data_activity_train_labels,
                data_activity_train_subject
            ),
            cbind(
                data_activity_test,
                data_activity_test_labels,
                data_activity_test_subject
            )
        )
    )
    
    # 3. Uses descriptive activity names to name the activities in
    #    the data set
    data_activity$activity <- as.factor(mapvalues(
        as.vector(data_activity$activity),
        from = as.vector(data_labels$id),
        to = as.vector(data_labels$label)
    ))
    
    # Clear Memory
    remove(
        data_features,
        data_labels,
        data_activity_train,
        data_activity_train_labels,
        data_activity_train_subject,
        data_activity_test,
        data_activity_test_labels,
        data_activity_test_subject,
        features,
        column_types_fwf,
        column_widths_fwf
    )
}

# 2. Extracts only the measurements on the mean
#    and standard deviation for each measurement.
mean_std_features <- grep(
    "mean\\.|std\\.|activity|subject",
    colnames(data_activity)
)
data_mean_std <- data_activity[, mean_std_features]

# 5. From the data set in step 4, creates a second, independent tidy data set
#    with the average of each variable for each activity and each subject.
data_activity_tidy <- group_by(data_mean_std, activity, subject) %>%
    summarise_each(funs(mean))

# Save Data
write.table(
    data_activity_tidy,
    file = "data_tidy.txt",
    sep = " ",
    row.name = FALSE
)