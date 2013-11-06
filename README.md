# Soup.io Backup

This script uses the soup.io RSS export to download all enclosed images.

Requires: wget

## Export RSS

![how to export rss](https://raw.github.com/wiki/manno/soup-io-backup/img/How%20to%20export.png)

## Download

Just start downloading:

    ./rssdownloader.rb soup_user_2013-05-23.rss

Download to a folder:

    ./rssdownloader.rb -d 2013 -v soup_user-2013-05-23.rss


