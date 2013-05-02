# BOMAAB - APPs are Boarding

This guide will describe a setup for self-hosted, always-updated download/IAP statistics visualized by [Panic's Status Board](http://www.panic.com/statusboard/).

## Requirements:
- server with Java, MySQL, Bash, PHP, Cron
- Apple developer account
- StatusBoard APP

## tl;dr

- copy <tt>update.sh</tt>, <tt>index.php</tt> and <tt>db.php</tt> to a folder of your web server
- download and decompress [Autoingestion](http://apple.com/itunesnews/docs/Autoingestion.class.zip) to that folder
- create the MySQL table described under "MySQL setup"
- open <tt>update.sh</tt> and enter your credentials in the header, enter them again in <tt>db.php</tt>  (note: if you don't wish to use your normal iTunes Connect user/password, you can create a "sales-only" sub-user with a different password)
- run update.sh manually and check if everything runs fine; create a crontab entry for regular updates
- open Status Board on your iPad, create a new "Graph", enter the URL to your webserver's folder

Enjoy your downloads!

<img src="https://raw.github.com/omichde/BOMAAB/master/screen.jpg">

# Setup

MacMini with OS-X Server and DynDNS is running fine for me even on a DSL connection but YMMV. For BOMAAB OS-X Server can easily be replaced by [MAMP](http://www.mamp.info/), upgrading to PRO gives you a nice graphical installer and control app. Although I have installed [MySQL](http://www.mysql.com/downloads/mysql/) from the original package I prefer [Sequel Pro](http://www.sequelpro.com) for data retrieval and management a lot - this tool is amazing! Apart from the Terminal I use [TextMate](http://macromates.com) for editing and [Cronnix](http://code.google.com/p/cronnix/) to edit my crontab - yes, I confess, I'm a visual coder, not a Terminal hacker.

# 1. Step: Importing reports into a local database

In the [APP Store Reporting Instructions](http://www.apple.com/itunesnews/docs/AppStoreReportingInstructions.pdf) Apple provides the link to the Autoingestion class. This Java class will be used to download the daily reports, which are initially stored as a CSV file and imported later into a MySQL database.

Create a folder anywhere you like for downloading the reports regularly, copy <tt>update.sh</tt> into this folder and open it to adjust your login credentials:

	APPLELOGIN="your-apple-id"
	APPLEPASSWORD="your-password"

This is your Apple-ID and password for [itunesconnect](https://itunesconnect.apple.com).

If you don't wish to use your normal iTunes Connect user/password, you can create a "sales-only" sub-user with a different password.

	APPLEVENDORID="your-vendor-id"

This number can be found in [itunesconnect](https://itunesconnect.apple.com) under "Sales and Trends". In the headline, after your login name, the number like <tt>80012345</tt> is your Vendor ID.

	MYSQLUSER="your-mysql-username"
	MYSQLPASSWORD="your-mysql-password"

This is your user name and password for the MySQL database. The downloaded daily reports will partially be stored into your MySQL table.

## MySQL setup

The scripts assume a database called <tt>itunesconnect</tt> with a table called <tt>sales</tt>. Its structure is closely modeled after the reports file format. Create the table with the following SQL command:

	CREATE TABLE `sales` (
	  `Provider` varchar(255),
	  `ProviderCountry` varchar(255),
	  `SKU` varchar(255),
	  `Developer` varchar(255),
	  `Title` varchar(255),
	  `Version` varchar(255),
	  `ProductTypeIdentifier` varchar(255),
	  `Units` int(11) NOT NULL,
	  `DeveloperProceeds` float NOT NULL,
	  `BeginDate` date NOT NULL,
	  `EndDate` date NOT NULL,
	  `CustomerCurrency` varchar(255),
	  `CountryCode` varchar(255),
	  `CurrencyOfProceeds` varchar(255),
	  `AppleIdentifier` varchar(255),
	  `CustomerPrice` float NOT NULL,
	  `PromoCode` varchar(255),
	  `ParentIdentifier` varchar(255),
	  `Subscription` varchar(255),
	  `Period` varchar(255)
	) ENGINE=MyISAM DEFAULT CHARSET=utf8;

## Synopsis: update.sh [YYYYMMDD]

The <tt>update.sh</tt> script accepts one optional parameter: the date for which to download and import the report in the format YYYYMMDD. If no parameter was given the script will load the daily report for **yesterday**!

*Caution:*
You cannot load a daily report for the current day, in fact you even have to wait half a day or longer (at least in Europe I'll have to wait until 18:00 to get the report for yesterday).

If the download succeeds, it will decompress the downloaded file, import its content into the database and finally remove the file.

## Test your setup

Run <tt>update.sh</tt> and you should see the message from the Autoingestion class (hopefully something like "File Downloaded Successfully"). You should now test wether the <tt>sales</tt> table contains the entries from this import, looking for entries with the same BeginDate date like the script date (assuming that you had downloads for your APP at this date).

*Hint:*
For debugging purposes the script logs error or success messages to a logfile under <tt>~/Library/Logs/update.log</tt> - open the Console app and you should see the entries there.

## Import old reports

Running <tt>update.sh</tt> with older dates will import those reports from Apple.

*Caution:*
You can only go back as much as 30 days but not longer!

## Regular report updates

On unix, you can add a crontab entry to call this <tt>update.sh</tt> script regularly. Open *Cronnix* and create a new entry, specifying the complete path to this script and a time when this script should be called.

Example for a script, running at 18:00 every day:

	0	18	*	*	*	/FOLDER-OF-SCRIPT/update.sh

# 2. Step: Generate a Status Board compatible report

Once importing the data went fine, you can generate graphs for Status Board with the <tt>index.php</tt> script: create a folder within reach of your web server, copy <tt>index.php</tt> and <tt>db.php</tt> there, open the <tt>db.php</tt> script and adjust your MySQL login credentials (this DB class is an old wrapper of mine aging years ago, it can easily be replaced by any other DB wrapper).

The <tt>index.php</tt> script currently looks for download numbers or In-App-Purchases only, generates those numbers for the last 30 days and groups them accordingly. It then outputs those numbers in the JSON format described in the [manual](http://www.panic.com/statusboard/docs/graph_tutorial.pdf).

## Generate graphs

Open Status Board, switch to the setup mode with the gear icon in the upper left corner, then add a Graph to your panel and enter the URL from your server into the Data URL field.

IAP graph example:

	http://your-server.com/path-to-folder/index.php?iap

Download graph example:

	http://your-server.com/path-to-folder/index.php?dl

Because download numbers are default, you can shorten the link like this:

	http://your-server.com/path-to-folder/

# Notes

- you can add htaccess/htpasswd or any other security measures to your graph script folder
- again for improved security you can seperate the <tt>update.sh</tt> script folder from your graph script folder
- apart from my university days long ago this is my first bash script - it's fairly tested but a unix geek could improve it, I bet
- direct purchase numbers are not handled - yet
- you can copy and modify the <tt>update.sh</tt> script to import even older daily reports you might have in a backup

# Links

- the MySQL structure and import idea based on [Björn Sållarp AppDailySales Import](http://blog.sallarp.com/fetching-app-store-sales-statistics-from-itunes-connect-into-mysql-using-appdailysales/) although I prefer Apples download Java class
- Apples [APP Store Reporting Instructions](http://www.apple.com/itunesnews/docs/AppStoreReportingInstructions.pdf) for explanation of CSV fields

## Contact

[Oliver Michalak](mailto:oliver@werk01.de) - [omichde](https://twitter.com/omichde)

## License

BOMAAB is available under the MIT license:

	Permission is hereby granted, free of charge, to any person obtaining a copy
	of this software and associated documentation files (the "Software"), to deal
	in the Software without restriction, including without limitation the rights
	to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
	copies of the Software, and to permit persons to whom the Software is
	furnished to do so, subject to the following conditions:

	The above copyright notice and this permission notice shall be included in
	all copies or substantial portions of the Software.

	THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
	IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
	FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
	AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
	LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
	OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
	THE SOFTWARE.

