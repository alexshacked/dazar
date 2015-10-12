from django.http import HttpResponse
from django.template.loader import get_template
from django.template import Context
from models import Locations
from models import Point

import re
import urllib2
import json

'The entry point to Dazar backend'
class DazarAPI:
    def register(self, request):
        body = json.loads(request.body)
        return HttpResponse(body['data'])

    def addTweet(self, request):
        return HttpResponse('Hello from addTweet')

    def getTweets(self, request):
        return HttpResponse('Hello from getTweets')

    # DEBUG API
    def debugAddAddress(self, request):
        initial_addr, formatted_addr = self._extractAddress(request)
        geocode = self._geocodeFromGoogle(formatted_addr)
        if geocode['status'] != 'OK':
            return HttpResponse(json.dumps(geocode))
        else:
            geocode = geocode['data']

        pt = Point(type = 'Point', coordinates = [float(geocode['lng']), float(geocode['lat'])] )
        try:
            doc = Locations.objects.create(address=initial_addr, point=pt)
            doc.save()
        except Exception as e:
            return HttpResponse(json.dumps(self._makeReturn('FAIL','Failed on access to MongoDb  ------- ' + e.message)))

        return HttpResponse(json.dumps(self._makeReturn('OK','OK')))

    # DEBUG API
    def debugNeighbours(self, request):
        initial_addr, formatted_addr = self._extractAddress(request)
        geocode = self._geocodeFromGoogle(formatted_addr)
        if geocode['status'] != 'OK':
            return HttpResponse(json.dumps(geocode))
        else:
            geocode = geocode['data']

        maxDistance = int(request.GET['radius'])
        lat = float(geocode['lat'])
        lng = float(geocode['lng'])
        query = { 'point': { '$near': {'$geometry': {'type':"Point", 'coordinates': [lng, lat]}, '$maxDistance': maxDistance } } }

        try:
            queryset = Locations.objects.raw_query(query)
            n = len(queryset) # probably a Django MongoDB Engine issue. Empty queryset does not support the contract API
        except Exception as e:
            return HttpResponse(json.dumps(self._makeReturn('FAIL','Failed on access to MongoDb  ------- ' + e.message)))

        res = self._parseMongoResponse(queryset);
        return HttpResponse(json.dumps(self._makeReturn('OK',res)))

    # DEBUG API
    def debugAll(self, request):
        try:
            queryset = Locations.objects.all()
            n = len(queryset) # probably a Django MongoDB Engine issue. Empty queryset does not support the contract API
        except Exception as e:
            return HttpResponse(json.dumps(self._makeReturn('FAIL','Failed on access to MongoDb  ------- ' + e.message)))

        res = self._parseMongoResponse(queryset);
        return HttpResponse(json.dumps(self._makeReturn('OK',res)))

    # DEBUG API
    def debugTruncate(self, request):
        try:
            Locations.objects.all().delete()
        except Exception as e:
            return HttpResponse(json.dumps(self._makeReturn('FAIL','Failed on access to MongoDb  ------- ' + e.message)))
        return HttpResponse(json.dumps(self._makeReturn('OK','OK')))

    # DEBUG API
    def debugGisUnittest(self, request):
        t = get_template('gisUnittest.html')
        html = t.render( Context({}) )
        return HttpResponse(html)

    #DEBUG API
    def debugApiConsole(self, request):
        t = get_template('apiConsole.html')
        html = t.render( Context({}) )
        return HttpResponse(html)

    def _makeReturn(self, status, payload):
        retblock = {}
        retblock['status'] = status
        if status == 'OK':
            retblock['data'] = payload
        else:
            retblock['info'] = payload

        return retblock

    def _parseMongoResponse(self, queryset):
        res = []
        for q in queryset:
            store = {}
            store['address'] = q.address
            store['coordinates'] = {'latitude':q.point.coordinates[1], 'longitude':q.point.coordinates[0]}
            res.append(store)

        return res

    def _geocodeFromGoogle(self, civil_addr):
        start = 'https://maps.googleapis.com/maps/api/geocode/json?address='
        mid = civil_addr
        end = '&key=AIzaSyAQ_Qt1ohwtRK84fy18fUpYllL0sZhX0wo'
        uri = start + mid + end

        geocode = urllib2.urlopen(uri).read()
        jsonObject = json.loads(geocode)
        if jsonObject['status'] != 'OK':
            return self._makeReturn('FAIL', 'google maps api - method geocode() failed')

        coords = jsonObject['results'][0]['geometry']['location']
        return self._makeReturn('OK', coords)

    def _extractAddress(self, request):
        initial_addr = request.GET['addr']
        formatted_addr = re.sub(r'[ ]+', '+', initial_addr)
        return initial_addr, formatted_addr








