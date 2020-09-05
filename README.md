# On Air

Simple API that you can put on your network somewhere (like on a raspberry pi or desktop computer). API looks like this:

`GET /status`: show status of all lights. Directly proxies to the Phillips Hue API so mostly useful for testing, maybe useful for building a dashboardi n the future

`GET light/:light_id/onair`: Set the specified light to be on air.

`GET light/:light_id/offair`: Set the specified light to be off air.

To get the light IDs for now you'll have to explore the Phillips Hue API yourself and grab them out of the API responses. Would be nice to improve this in the future!

## Installing and running
1. `docker pull dmiller/onair:latest`
2. `docker run -d -e PHILLIPS_HUE_USER_ID='MY_ID' -e PHILLIPS_HUE_BRIDGE_IP='192.168.42.80' -p 4567:4567 dmiller/onair:latest`