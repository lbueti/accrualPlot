#' accrual_create_df
#'
#' Creates a data frame that contains the absolute and cumululative number of patients
#' recruited at each date from a vector with enrollment dates.
#'
#' @param enrollment_dates dates on which patients are enrolled, date vector
#' @param start_date date when recruitment started. Single date (used for all sites in by),
#'  date vector (with the same length the number of distinct sites in by),
#'  "common" (first date overall) or "site" (first date for each site, default).
#' @param current_date date of the data export or database freeze.
#' 	Single date, date vector (with the same length the number of distinct sites in by),
#'  "common" (last date overall, default) or "site" (first date for each site).
#' @param force_start0 logical, adds an extra 0 line to the accrual data frame in cases
#'  where a start date is given and corresponds to the earliest enrollment date.
#' @param by vector with sites, has to have the same length as enrollment dates,
#' generates a list with accrual data frames for each site
#' @param overall logical indicates that accrual_df contains a summary with all sites (only if by is not NA)
#' @param name_overall name of the summary with all sites (if by is not NA and overall==TRUE)
#' @param pos_overall overall as last or first element of the list (if by is not NA and overall==TRUE)
#'
#' @return Returns a data frame (or a list of data frames if by is not NA)
#' with three columns "Date", "Freq" and "Cumulative" with each
#' date with an accrual and the absolute and cumulative number of patients accrued.
#' @export
#' @examples
#' \donttest{
#' set.seed(2020)
#' enrollment_dates <- as.Date("2018-01-01") + sort(sample(1:30, 50, replace=TRUE))
#' accrual_create_df(enrollment_dates)
#' # different start and current date
#' accrual_create_df(enrollment_dates,start_date=as.Date("2017-12-01"),
#' current_date=as.Date("2018-03-01"))
#' #by site
#' set.seed(2020)
#' centers<-sample(c("Site 1","Site 2","Site 3"),length(enrollment_dates),replace=TRUE)
#' accrual_create_df(enrollment_dates,by=centers)
#' }
accrual_create_df <- function(enrollment_dates,
                              start_date="site",
                              current_date="common",
                              force_start0=TRUE,
                              by=NA,
                              overall=TRUE,
                              name_overall="Overall",
							  pos_overall=c("last","first")) {


  check_date(enrollment_dates)
  if(any(is.na(enrollment_dates))) stop("'enrollment_dates' contains NA values")
  pos_overall<-match.arg(pos_overall)

   if (sum(!is.na(by))==0) {
    nc<-1; nct<-1; byt<-0
  } else {
    if (is.factor(by)) {lc<-levels(by)} else {lc<-sort(unique(by))}
	nc<-length(lc)
    nct<-ifelse(overall==TRUE,nc+1,nc)
    byt<-1
  }

  if (!any(start_date[1] %in% c("site","common"))) {
	check_date(start_date)
	check_length(start_date,by)
	start_date<-mult(start_date,nc)
	if (nct>nc) {start_date<-c(start_date,min(start_date))}
  } else {

	if(length(start_date)!=1) {
		stop(paste0(start_date," should be of class Date or a single character 'common' or 'site'"))
	}
	if (start_date=="common") {
		start_date<-rep(min(enrollment_dates),nct)
	} else {
	   start_date<-rep(NA,nct)
    }
  }

  if (!any(current_date[1] %in% c("site","common"))) {
	check_date(current_date)
	check_length(current_date,by)
	current_date<-mult(current_date,nc)
	if (nct>nc) {current_date<-c(current_date,max(current_date))}
  } else {
	if(length(current_date)!=1) {
		stop(paste0(current_date," should be of class Date or a single character 'common' or 'site'"))
	}
	if (current_date=="common") {
		current_date<-rep(max(enrollment_dates),nct)
	} else {
	   current_date<-rep(NA,nct)
    }
  }

  accrual_df<-numeric(0)

  if (byt==0) {
    ed<-enrollment_dates
    accrual_df<-genadf(enrollment_dates=ed,start_date=start_date[1],current_date=current_date[1],
		force_start0=force_start0)
  }
  else {
     for (i in 1:nc) {
       ed<-enrollment_dates[by==lc[i]]
	   adf<-genadf(enrollment_dates=ed,start_date=start_date[i],current_date=current_date[i],
		force_start0=force_start0,name=lc[[i]])
	   accrual_df<-append(accrual_df,list(adf))
	   names(accrual_df)[i]<-lc[i]
	 }
  }

  if (byt!=0 & overall) {
    ed<-enrollment_dates
    adf<-genadf(enrollment_dates=ed,start_date=start_date[nct],current_date=current_date[nct],
                force_start0=force_start0,warning=FALSE)
    if (pos_overall=="last") {
      accrual_df<-append(accrual_df,list(name_overall=adf))
    } else {
      accrual_df<-append(list(name_overall=adf),accrual_df)
    }
    names(accrual_df)[names(accrual_df)=="name_overall"]<-name_overall
  }

  if (byt == 1){
    accrual_df <- lapply(accrual_df, function(x) {
      class(x) <- c("accrual_df", class(x))
      x
    })
    class(accrual_df) <- c("accrual_list", "accrual_df", class(accrual_df))
    attr(accrual_df, "name_overall") <- name_overall
  } else {
    class(accrual_df) <- c("accrual_df", class(accrual_df))

  }

  # class(accrual_df) <- c("accrual_df", class(accrual_df))
  return(accrual_df)
}

