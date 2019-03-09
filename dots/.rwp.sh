#!/usr/bin/env python

import calendar
import imghdr
import json
import os
import requests
import shutil
import subprocess
import subprocess
import time
import urllib
import urlparse

wallpaper_path = "/tmp/wp-" + str(calendar.timegm(time.gmtime()))
subreddit = "wallpaper"
extensions = ["jpeg", "jpg", "png"]

SCRIPT = """/usr/bin/osascript<<END
tell application "System Events" to tell every desktop to set picture to "%s"
END"""

def set_desktop_background(filename):
    subprocess.Popen(SCRIPT%filename, shell=True)

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
        print " --> Skipping due to resolution being ", width, height
        continue

    if aspect != 1.78:
        print " --> Skipping due to aspect being ", aspect
        continue


    path = urlparse.urlparse(url).path
    ext = (os.path.splitext(path)[1]).replace(".", "").lower()

    try:
        extensions.index(ext)
    except Exception as e:
        print " --> Skipping due to invalid format being ", ext
        continue

    urllib.urlretrieve(post["data"]["url"], wallpaper_path + ext)

    image_ext = imghdr.what(wallpaper_path + ext)
    try:
        extensions.index(image_ext)
    except Exception as e:
        print " --> Skipping due to invalid image being ", image_ext
        continue

    print " --> OK. Chaning wallpaper"

    dotPath = os.path.expanduser("~/.wallpaper." + ext)
    shutil.move(wallpaper_path + ext, dotPath)
    set_desktop_background(dotPath)

    break