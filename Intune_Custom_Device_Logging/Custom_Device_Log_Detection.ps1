#This script is made to run once a week on Wednesdays. On Wednesday's, the issue will be present and the script will run.  Other days of the week will show up as 'resolved'

$date = get-date

if($date.dayofweek -eq "Wednesday"){
    write-host "Log Time!"
    exit 1
}
else{
    write-host "No logs today"
    exit 0
}