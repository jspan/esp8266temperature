port = 80
pin_dht = 5
pin_relay = 6

pollperiod = 2000
poll_count_max = 60000 / pollperiod

humi = "00"
temp = "00"

poll_count = 0

function read_sensor()
    local status, t, h, td, hd = dht.read(pin_dht)
    if status == dht.OK then
        print("DHT Temperature:"..temp..";".."Humidity:"..humi)
        humi = h
        temp = t
    elseif status == dht.ERROR_CHECKSUM then
        print( "DHT Checksum error." )
    elseif status == dht.ERROR_TIMEOUT then
        print( "DHT timed out." )
    end
end
function tick()
    read_sensor() 
    poll_count = poll_count + 1 
    if poll_count == poll_count_max then 
        poll_count = 0
        ip = wifi.sta.getip()
        if not ip then
            wifi.sta.connect()
            ip = wifi.sta.getip() 
            print(ip)
        end
    end
end

read_sensor()
tmr.alarm(1, pollperiod, 1, tick)
gpio.mode(pin_relay, gpio.OUTPUT)

httphandler = function(connection, payload)
    local html = "";
    local _, _, method, path, vars = string.find(payload, "([A-Z]+) (.+)?(.+) HTTP");
    if method == nil then
        _, _, method, path = string.find(payload, "([A-Z]+) (.+) HTTP");
    end
    local _GET = {}
    if vars ~= nil then
        for k, v in string.gmatch(vars, "(%w+)=(%w+)&*") do
            _GET[k] = v
        end
    end

    local tempF = temp * 9/5 + 32
    html = html.."<h1>CONTROL PANEL</h1>";
    html = html.."<p>Switch <a href=\"?pin=ON1\"><button>ON</button></a>&nbsp;<a href=\"?pin=OFF1\"><button>OFF</button></a></p>";
    html = html..'<p><input style="text-align: center" type="text" size=4 name="j" value="'..humi..'"> % Humidity</p>\
    <p><input style="text-align: center"type="text" size=4 name="p" value="'..temp..'"> Temp (C)</p>\
    <p><input style="text-align: center"type="text" size=4 name="f" value="'..tempF..'"> Temp (F)</p>'
    local _on,_off = "",""
    if(_GET.pin == "ON1")then
        gpio.write(pin_relay, gpio.HIGH);
    elseif(_GET.pin == "OFF1")then
        gpio.write(pin_relay, gpio.LOW);
    end
    connection:send(html);
    collectgarbage();
end

srv = net.createServer(net.TCP)
srv:listen(port,function(c)
    c:on("receive",function(c,d)
        tmr.stop(6)
        -- check whether the request was sent by putty or luatool 
        if (d:sub(1,6) == string.char(255,251,31,255,251,32) or d:sub(1,5) == "file.") then
            -- switch to telnet service
            node.output(function(s)
                if c ~= nil then c:send(s) end
            end,0)
            c:on("receive",function(c,d)
                if d:byte(1) == 4 then c:close() -- ctrl-d to exit
                else node.input(d) end
            end)
            c:on("disconnection",function(c)
                node.output(nil)
            end)
            node.input("\r\n")
            if  d:sub(1,5) == "file." then
                node.input(d)
            end
        else
            c:on("sent", function(c) c:close() end)
            -- handle http request
            httphandler(c,d)
        end
    end)
    -- luatool needs to receive a response before it sends anything
    tmr.alarm(6,500,0,function() c:send("HTTP/1.1 200 OK\r\n\r\n") end )
end)
