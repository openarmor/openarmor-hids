<?php
/* openarmor 2 RSS script.
 * by Daniel B. Cid ( dcid @ theopenarmor.org)
 *
 * Just upload it to any web-accessible directory, and make
 * sure the web server can access the openarmor alerts log file.
 */


$openarmor_log = "/var/openarmor/logs/alerts/alerts.log";
if(!is_readable($openarmor_log))
{
    echo "ERROR: Unable to access $openarmor_log\n";
    echo "*TIP: Make sure your web server can access that file. \n";
    exit(1);
}

$timelp = filemtime($openarmor_log);
$fh = fopen($openarmor_log, "r");
if(!$fh)
{
    exit(1);
}

if(filesize($openarmor_log) > 30000)
{
    fseek($fh, -30000, SEEK_END);
    $line = fgets($fh, 4096);
}


$lastlines = array();
$event = array();
while($line = fgets($fh, 4096))
{
    $line = trim($line);
    if($line == "")
    {
        continue;
    }

    if(strncmp($line, "** Alert ", 9) == 0)
    {
        if(strncmp($event, "** Alert ", 9) == 0)
        {
            array_push($lastlines, $event);
        }
        unset($event);
        $event = array();
        $event[] = htmlspecialchars($line);
    }
    else
    {
        $event[] = htmlspecialchars($line);
    }
}
fclose($fh);

$lastlines = array_reverse($lastlines);
$myhost = gethostname();
if($myhost === FALSE)
{
    $myhost = "";
}

echo '<?xml version="1.0" encoding="UTF-8"?>
<?xml-stylesheet href="/css/rss.css" type="text/css"?>
<rss version="2.0">
<channel>
<title>openarmor '.$myhost.' RSS Feed</title>
<link>http://theopenarmor.org</link>
<description>openarmor RSS Feed for '.$myhost.'</description>
<language>en-us</language>
<lastBuildDate>'.date("r", $timelp).'</lastBuildDate>
<pubDate>'.date("r", $timelp).'</pubDate>
<copyright>(C) theopenarmor.org 2008-2011</copyright>
<generator>theopenarmor.org RSS feed</generator>
<ttl>30</ttl>
<webMaster>dcid@theopenarmor.org</webMaster>

<image>
  <title>openarmor Alert Feed</title>
  <url>http://www.theopenarmor.org/img/openarmor_logo.jpg</url>
  <link>http://theopenarmor.org</link>
</image>
';

foreach($lastlines as $myentry)
{
echo $myentry;

    if(preg_match("/^.. Alert (\d+)\./", $myentry[0], $regs, PREG_OFFSET_CAPTURE, 0))
    {
        $myunixtime = $regs[1][0];
    }
    else
    {
        continue;
    }


    echo '
    <item>
        <title>'.$myentry[2]." ,from ".substr($myentry[1], 20).'</title>
        <link>http://theopenarmor.org</link>
        <guid isPermaLink="false">'.$myentry[0].'</guid>
        <description><![CDATA[';

    foreach($myentry as $myline){ echo $myline."<br />\n"; }

    echo '
        ]]></description>
        <pubDate>'.date("r", $myunixtime).'</pubDate>
    </item>
    ';
}

echo '
</channel>
</rss>
';


?>
