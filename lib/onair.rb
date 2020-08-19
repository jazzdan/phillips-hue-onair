require 'sinatra'
require 'sinatra/json'
require 'http'

LIVING_ROOM_LIGHT = 9
BEDROOM_LIGHT = 10

ON_AIR_COLOR = {bri: 254, hue: 46563, sat: 213}
OFF_AIR_COLOR = {bri: 254, hue: 52349, sat: 21}
# TODO(dmiller): more states

def light_is(status, color)
    puts status
    status[:bri] == color[:bri] && status[:hue] == color[:hue] && status[:sat] == color[:sat]
end

def light_status(status)
    if light_is(status, ON_AIR_COLOR)
        "ON_AIR"
    else
        "OFF_AIR"
    end
end

# NOTE(dmiller): we could instead make one request for all of the lights but this feels cleaner
# and performance doesn't really matter
def get_light_status(id)
    # TODO(dmiller): should be possible to init this on start?
    user_id = ENV["PHILLIPS_HUE_USER_ID"]
    bridge_ip = ENV["PHILLIPS_HUE_BRIDGE_IP"]

    resp = HTTP.get("http://#{bridge_ip}/api/#{user_id}/lights/#{id}")
    if !resp.status.success?
        puts "Error getting light status"
        puts resp
        return
    end

    js = resp.parse

    light_status(js)
end

def set_light(id, color)
    # TODO(dmiller): should be possible to init this on start?
    user_id = ENV["PHILLIPS_HUE_USER_ID"]
    bridge_ip = ENV["PHILLIPS_HUE_BRIDGE_IP"]

    payload = color
    payload[:on] = true

    resp = HTTP.put("http://#{bridge_ip}/api/#{user_id}/lights/#{id}/state", :json => payload)
    if !resp.status.success?
        puts "Error setting light"
        puts resp
        return
    end
end

get '/status' do
    living_room_light_status = get_light_status(LIVING_ROOM_LIGHT)
    bedroom_light_status = get_light_status(BEDROOM_LIGHT)
    json :living_room_light => living_room_light_status, :bedroom_light => bedroom_light_status
end

get '/light/:light/onair' do
    set_light(params['light'], ON_AIR_COLOR)
end

get '/light/:light/offair' do
    set_light(params['light'], OFF_AIR_COLOR)
end