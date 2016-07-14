pin_led = 7
gpio.mode(pin_led, gpio.OUTPUT)

function setLed(led_on)
    if led_on then
        gpio.write(pin_led, gpio.HIGH)
    else 
        gpio.write(pin_led, gpio.LOW)
    end
end

setLed(true)
