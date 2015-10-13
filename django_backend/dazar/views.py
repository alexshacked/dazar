from django.http import HttpResponse
from django.template.loader import get_template
from django.template import Context
from models import Locations
from models import Point

import re
import urllib2
import json
import logging
logger = logging.getLogger(__name__)

'The entry point to Dazar backend'
class DazarAPI:
    def registerVendor(self, request):
        valid = self._validateRequest(request)
        if valid is not None:
            return HttpResponse(json.dumps(self._makeReturn('FAIL', 'registerVendor', valid)))
        self._doLog('DEBUG', 'registerVendor', request.body)
        body = json.loads(request.body)

        response = {}
        response['vendorId'] = 1111
        return HttpResponse(json.dumps(self._makeReturn('OK', 'registerVendor', response)))

    def addTweet(self, request):
        return HttpResponse('Hello from addTweet')

    def getTweets(self, request):
        return HttpResponse('Hello from getTweets')

    # DEBUG API
    def debugAddAddress(self, request):
        initial_addr, formatted_addr = self._extractAddress(request)
        geocode = self._geocodeFromGoogle(formatted_addr, 'debugAddAddress')
        if geocode['status'] != 'OK':
            return HttpResponse(json.dumps(geocode))
        else:
            geocode = geocode['data']

        pt = Point(type = 'Point', coordinates = [float(geocode['lng']), float(geocode['lat'])] )
        try:
            doc = Locations.objects.create(address=initial_addr, point=pt)
            doc.save()
        except Exception as e:
            return HttpResponse(json.dumps(self._makeReturn('FAIL','debugAddAddress', 'Failed on access to MongoDb  ------- ' + e.message)))

        return HttpResponse(json.dumps(self._makeReturn('OK', 'debugAddAddress', 'OK')))

    # DEBUG API
    def debugNeighbours(self, request):
        initial_addr, formatted_addr = self._extractAddress(request)
        geocode = self._geocodeFromGoogle(formatted_addr, 'debugNeighbours')
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
            return HttpResponse(json.dumps(self._makeReturn('FAIL', 'debugNeighbours', 'Failed on access to MongoDb  ------- ' + e.message)))

        res = self._parseMongoResponse(queryset);
        return HttpResponse(json.dumps(self._makeReturn('OK', 'debugNeighbours', res)))

    # DEBUG API
    def debugAll(self, request):
        try:
            queryset = Locations.objects.all()
            n = len(queryset) # probably a Django MongoDB Engine issue. Empty queryset does not support the contract API
        except Exception as e:
            return HttpResponse(json.dumps(self._makeReturn('FAIL', 'debugAll', 'Failed on access to MongoDb  ------- ' + e.message)))

        res = self._parseMongoResponse(queryset);
        return HttpResponse(json.dumps(self._makeReturn('OK', 'debugAll', res)))

    # DEBUG API
    def debugTruncate(self, request):
        try:
            Locations.objects.all().delete()
        except Exception as e:
            return HttpResponse(json.dumps(self._makeReturn('FAIL', 'debugTruncate', 'Failed on access to MongoDb  ------- ' + e.message)))
        return HttpResponse(json.dumps(self._makeReturn('OK', 'debugTruncate', 'OK')))

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

    def _makeReturn(self, status, cmd, payload):
        retblock = {}
        retblock['status'] = status
        retblock['command'] = cmd
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

    def _geocodeFromGoogle(self, civil_addr, cmd):
        start = 'https://maps.googleapis.com/maps/api/geocode/json?address='
        mid = civil_addr
        end = '&key=AIzaSyAQ_Qt1ohwtRK84fy18fUpYllL0sZhX0wo'
        uri = start + mid + end

        geocode = urllib2.urlopen(uri).read()
        jsonObject = json.loads(geocode)
        if jsonObject['status'] != 'OK':
            return self._makeReturn('FAIL', cmd, 'google maps api - method geocode() failed')

        coords = jsonObject['results'][0]['geometry']['location']
        return self._makeReturn('OK', cmd, coords)

    def _extractAddress(self, request):
        initial_addr = request.GET['addr']
        formatted_addr = re.sub(r'[ ]+', '+', initial_addr)
        return initial_addr, formatted_addr

    def _validateRequest(self, req):
        if req.body == None:
            return 'request body is null'
        elif len(req.body) == 0:
            return 'request body is an empty string'
        else:
            return None

    def _doLog(self, level, cmd, msg):
        fullMsg = "Request: " + cmd + '\n' + msg

        if level == 'DEBUG':
            logger.debug(fullMsg)








