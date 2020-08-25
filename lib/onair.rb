require 'sinatra'
require 'sinatra/json'
require 'http'
require 'pp'

# TODO(dmiller): make sure that env variables are set

LIVING_ROOM_LIGHT = 9
BEDROOM_LIGHT = 10

ON_AIR_COLOR = {bri: 254, hue: 46563, sat: 213}
OFF_AIR_COLOR = {bri: 254, hue: 52349, sat: 21}
# TODO(dmiller): more states

# map of light ID to last known state that was not set by onair
$last_known_manual_state = {}

def light_is(status, color)
    status[:bri] == color[:bri] && status[:hue] == color[:hue] && status[:sat] == color[:sat]
end

def on_or_off_air(status)
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

    url = "http://#{bridge_ip}/api/#{user_id}/lights/#{id}"
    resp = HTTP.get(url)
    if !resp.status.success?
        puts "Error getting light status"
        puts resp
        return
    end

    resp.parse
end

def status_set_by_onair(status)
    s = status["state"]
    light_is(s, ON_AIR_COLOR) || light_is(s, OFF_AIR_COLOR)
end

def set_light(id, color)
    user_id = ENV["PHILLIPS_HUE_USER_ID"]
    bridge_ip = ENV["PHILLIPS_HUE_BRIDGE_IP"]
    allowed_keys = ["on", "bri", "hue", "sat"]

    payload = color.select { |key, _| allowed_keys.include?(key)}
    if !payload.key?("on")
        payload["on"] = true
    end

    pp payload

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
    id = params['light']
    current_status = get_light_status(id)
    if !status_set_by_onair(current_status)
        puts "We didn't set the current status, so let's store it"
        $last_known_manual_state[id] = current_status
    end

    set_light(params['light'], ON_AIR_COLOR)
end

get '/light/:light/offair' do
    light = params['light']
    color = OFF_AIR_COLOR
    if $last_known_manual_state.key?(light) 
        color = $last_known_manual_state[light]["state"]
        pp color
        $last_known_manual_state.delete(light)
    end
    set_light(params['light'], color)
end