# geolocation.coffee
# Copyright 2019 Patrick Meade.
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as published
# by the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.
#----------------------------------------------------------------------

geo_success = (position) ->
    $('#latitude').val position.coords.latitude
    $('#longitude').val position.coords.longitude
    $(':input[type="submit"]').prop 'disabled', false

geo_error = ->

navigator.geolocation.watchPosition geo_success, geo_error,
    enableHighAccuracy: true
    maximumAge: 30000
    timeout: 25000

window.updatePosition = ->
  navigator.geolocation.getCurrentPosition geo_success

#----------------------------------------------------------------------
# end of geolocation.coffee
