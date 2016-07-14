wifi.setmode(wifi.STATION)
wifi.sta.config(SSID, PASSWD)
dofile("server.lua")
