from django.http import HttpResponse
from django.template.loader import get_template
from django.template import Context
from models import Point
from models import Vendors
from models import Locations
from models import Tweets
from pymongo.errors import ServerSelectionTimeoutError

import re
import urllib2
import json
import logging
import datetime
logger = logging.getLogger(__name__)

'The entry point to Dazar backend'
class DazarAPI:
    def registerVendor(self, request):
        # ingest request
        invalid = self._validateRequest(request)
        if invalid is not None:
            return HttpResponse(json.dumps(self._makeReturn('FAIL', 'registerVendor', invalid)))
        self._doLog('DEBUG', 'registerVendor', request.body)
        body = json.loads(request.body)

        # get coordinates for the business location
        formatted_address = self._makeGoogleAddress(body['address'])
        geocode = self._geocodeFromGoogle(formatted_address, "getCoordinates")
        if geocode['status'] == 'FAIL':
            return HttpResponse(json.dumps(geocode))

        # make sure this vendor is not registered already
        try:
            vendor = Vendors.objects.get(name =body['vendor'], phone=body['phone'] )
            # if mongodb did not throw an exception, it means the vendor is already in. we must leave.
            return HttpResponse(json.dumps(self._makeReturn('FAIL','registerVendor', 'Vendor <' + body['vendor'] + '> is already registered')))
        except Exception as e:
            pass; # this is good actually. means the object does not exist

        # insert the new vendor in mongodb
        pt = Point(type = 'Point', coordinates = [float(geocode['data']['lng']), float(geocode['data']['lat'])] )
        now = datetime.datetime.now()
        try:
            doc = Vendors.objects.create(name =body['vendor'], address=body['address'],
                                         phone=body['phone'], tags=body['tags'],location=pt, registrationTime = now)
            doc.save()
        except Exception as e:
            return HttpResponse(json.dumps(self._makeReturn('FAIL','registerVendor', 'Failed on access to MongoDb  ------- ' + e.message)))

        # respond
        response = {}
        response['vendorId'] = doc.id
        return HttpResponse(json.dumps(self._makeReturn('OK', 'registerVendor', response)))

    def addTweet(self, request):
        # ingest request
        invalid = self._validateRequest(request)
        if invalid is not None:
            return HttpResponse(json.dumps(self._makeReturn('FAIL', 'addTweet', invalid)))
        self._doLog('DEBUG', 'addTweet', request.body)
        body = json.loads(request.body)

        # get the vendor data from the vendors table in mongodb
        try:
            vendor = Vendors.objects.get(id = body['vendorId'])
        except Exception as e:
            return HttpResponse(json.dumps(self._makeReturn('FAIL','addTweet', 'vendorId <' + body['vendorId'] + '> is not registered')))

        # find out if this vendor creates a new tweet or updates an existing one
        newTweet = False
        try:
            tweet = Tweets.objects.get(vendorId = body['vendorId'])
        except Exception as e:
            if type(e) is ServerSelectionTimeoutError:
                return HttpResponse(json.dumps(self._makeReturn('FAIL','addTweet', 'mongodb is down')))
            newTweet = True

        # create or update the tweet
        if newTweet == True:
            now = datetime.datetime.now()
            try:
                doc = Tweets.objects.create(message =body['tweet'], vendorId = body['vendorId'], vendorName = vendor.name, vendorAddress = vendor.address,
                                         vendorPhone = vendor.phone, vendorTags = vendor.tags, vendorLocation = vendor.location,
                                         creationTime = now)
                doc.save()
            except Exception as e:
                return HttpResponse(json.dumps(self._makeReturn('FAIL','addTweet', 'Failed on access to MongoDb  ------- ' + e.message)))
        else: # update
            try:
                tweet.message = body['tweet']
                tweet.save()
            except Exception as e:
                return HttpResponse(json.dumps(self._makeReturn('FAIL','addTweet', 'Failed on access to MongoDb  ------- ' + e.message)))

        return HttpResponse(json.dumps(self._makeReturn('OK', 'addTweet', 'OK')))

    def getTweets(self, request):
        invalid = self._validateRequest(request)
        if invalid is not None:
            return HttpResponse(json.dumps(self._makeReturn('FAIL', 'getTweets', invalid)))
        self._doLog('DEBUG', 'getTweets', request.body)
        body = json.loads(request.body)

        # vendor = Vendors.objects.get(id = '561e60c780b84ab78ff07c0f')

        one = {}
        one['vendorName'] = 'Sasha'
        one['address'] = '30 Dizengoff, Tel Aviv, Israel'
        one['tweet'] = 'Every third item for three'
        one['coordinates'] = {}
        one['coordinates']['latitude'] = 32.34567
        one['coordinates']['longitude'] = 34.3173545
        response = []
        response.append(one)
        return HttpResponse(json.dumps(self._makeReturn('OK', 'getTweets', response)))

    # DEBUG API
    def debugGetCoordinates(self, request):
        invalid = self._validateRequest(request)
        if invalid is not None:
            return HttpResponse(json.dumps(self._makeReturn('FAIL', 'getCoordinates', invalid)))
        self._doLog('DEBUG', 'debugGetCoordinates', request.body)
        body = json.loads(request.body)

        address = self._makeGoogleAddress(body['address'])
        geocode = self._geocodeFromGoogle(address, "getCoordinates")
        return HttpResponse(json.dumps(geocode))

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

        try:
            geocode = urllib2.urlopen(uri).read()
        except Exception as e:
            return self._makeReturn('FAIL', cmd, 'google maps api - method geocode() failed: ' + e.msg)
        jsonObject = json.loads(geocode)
        if jsonObject['status'] != 'OK':
            return self._makeReturn('FAIL', cmd, 'google maps api - method geocode() failed')

        coords = jsonObject['results'][0]['geometry']['location']
        return self._makeReturn('OK', cmd, coords)

    def _makeGoogleAddress(self, addr):
        return re.sub(r'[ ]+', '+', addr)

    def _extractAddress(self, request):
        initial_addr = request.GET['addr']
        formatted_addr = self._makeGoogleAddress(initial_addr)
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








