#!/bin/bash
# enter your credentials here:
APPLELOGIN="your-apple-id"
APPLEPASSWORD="your-password"
APPLEVENDORID="your-vendor-id"
MYSQLUSER="your-mysql-username"
MYSQLPASSWORD="your-mysql-password"

cd $(dirname $0)
if [[ -n $1 ]]; then         
	DATE="$1"
else
	DATE=$(date -v -1d +%Y%m%d)
fi
java Autoingestion $APPLELOGIN $APPLEPASSWORD $APPLEVENDORID Sales Daily Summary $DATE
FNAME="S_D_${APPLEVENDORID}_${DATE}.txt"
if [ -f "$FNAME.gz" ]; then
	gunzip "$FNAME.gz"
	/usr/local/mysql/bin/mysql --user=$MYSQLUSER --password=$MYSQLPASSWORD --database=itunesconnect -e "delete from sales where BeginDate='$DATE' and EndDate='$DATE'"
	/usr/local/mysql/bin/mysql --user=$MYSQLUSER --password=$MYSQLPASSWORD --database=itunesconnect -e "load data local infile '$FNAME' into table sales fields terminated by '\t' lines terminated by '\n' ignore 1 lines (Provider,ProviderCountry,SKU,Developer,Title,Version,ProductTypeIdentifier,Units,DeveloperProceeds,@BeginDate,@EndDate,CustomerCurrency,CountryCode,CurrencyOfProceeds,AppleIdentifier,CustomerPrice,PromoCode,ParentIdentifier,Subscription,Period) SET BeginDate=str_to_date(@BeginDate, '%m/%d/%Y'), EndDate=str_to_date(@EndDate, '%m/%d/%Y')"
	rm $FNAME
	echo "$(date "+%Y-%m-%d %H:%M:%S"): $DATE imported" >> ~/Library/Logs/update.log
else
	echo "$(date "+%Y-%m-%d %H:%M:%S"): no file $FNAME.gz" >> ~/Library/Logs/update.log
fi