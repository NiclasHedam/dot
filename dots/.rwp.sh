#!/usr/bin/env python

import calendar
import imghdr
import json
import os
import platform
import requests
import shutil
import subprocess
import subprocess
import time
import urllib
import urlparse

wallpaper_path = "/tmp/wp-" + str(calendar.timegm(time.gmtime()))
subreddit = "wallpaper"
extensions = ["jpg", "jpeg", "png"]

def set_desktop_background(filename):
    if platform.system() == 'Darwin':
        os.system("osascript -e 'tell application \"System Events\" to tell every desktop to set picture to \"" + filename + "\"'")
        os.system("osascript -e 'tell application \"Finder\" to set desktop picture to POSIX file \"" + filename + "\"'")
        os.system("killall -9 Dock")
    else:
        os.system("gsettings set org.gnome.desktop.background picture-uri file:///" + filename)

def getsizes(uri):
    # get file size *and* image size (None if not known)
    file = urllib.urlopen(uri)
    size = file.headers.get("content-length")
    if size: size = int(size)
    p = ImageFile.Parser()
    while 1:
        data = file.read(1024)
        if not data:
            break
        p.feed(data)
        if p.image:
            return size, p.image.size
            break
    file.close()
    return size, None

result = requests.get(
    "https://api.reddit.com/r/" + subreddit + "/top?t=day&limit=50",
    headers = {
        'User-Agent': 'Not Python',
    }
)

posts = json.loads(result.content)["data"]["children"]

for post in posts:
    url     = post["data"]["url"]
    width   = post["data"]["preview"]["images"][0]["source"]["width"]
    height  = post["data"]["preview"]["images"][0]["source"]["height"]
    aspect  = float("{0:.2f}".format(float(width)/float(height)))

    print "Found " + url

    if post["data"]["over_18"] == True:
        print " --> Skipping due to NSFW"
        continue

    if width < 1920 or height < 1080:
        print " --> Skipping due to resolution being", width, height
        continue

    if aspect != 1.78:
        print " --> Skipping due to aspect being", aspect
        continue


    path = urlparse.urlparse(url).path
    ext = (os.path.splitext(path)[1]).replace(".", "").lower()

    try:
        extensions.index(ext)
    except Exception as e:
        print " --> Skipping due to invalid format being", ext
        continue

    urllib.urlretrieve(post["data"]["url"], wallpaper_path + ext)

    image_ext = imghdr.what(wallpaper_path + ext)
    try:
        extensions.index(image_ext)
    except Exception as e:
        print " --> Skipping due to invalid image being", image_ext
        continue

    print " --> OK. Changing wallpaper"

    dotPath = os.path.expanduser("~/Wallpaper")
    shutil.move(wallpaper_path + ext, dotPath)
    print " --> Path: " + dotPath
    set_desktop_background(dotPath)

    break
