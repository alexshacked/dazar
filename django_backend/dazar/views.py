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
        performanceMessage = ''
        timeEnterFunc = datetime.datetime.now()

        invalid = self._validateRequest(request)
        if invalid is not None:
            return HttpResponse(json.dumps(self._makeReturn('FAIL', 'registerVendor', invalid)))
        self._doLog('DEBUG', 'registerVendor', request.body)
        body = json.loads(request.body)

        # vendor needs to specify the market category of the business
        tags = body['tags']
        if 'all' in tags:
            return HttpResponse(json.dumps(self._makeReturn('FAIL', 'registerVendor', 'need to specify the business sector: cafes, restaurants, clothing, ...')))

        # get coordinates for the business location
        formatted_address = self._makeGoogleAddress(body['address'])

        timeStartGoogle = datetime.datetime.now()
        performanceMessage += self._logGather('parsing request', timeEnterFunc, timeStartGoogle)

        geocode = self._geocodeFromGoogle(formatted_address, "getCoordinates")

        timeEndGoogle = datetime.datetime.now()
        performanceMessage += self._logGather('geocode from google', timeStartGoogle, timeEndGoogle)

        if geocode['status'] == 'FAIL':
            return HttpResponse(json.dumps(geocode))

        # make sure this vendor is not registered already
        try:
            vendor = Vendors.objects.get(name =body['vendor'], phone=body['phone'] )
            # if mongodb did not throw an exception, it means the vendor is already in. we must leave.
            return HttpResponse(json.dumps(self._makeReturn('FAIL','registerVendor', 'Vendor <' + body['vendor'] + '> is already registered')))
        except Exception as e:
            pass; # this is good actually. means the object does not exist

        timeMongoGet = datetime.datetime.now()
        performanceMessage += self._logGather('mongo get', timeEndGoogle, timeMongoGet)

        # insert the new vendor in mongodb
        pt = Point(type = 'Point', coordinates = [float(geocode['data']['lng']), float(geocode['data']['lat'])] )
        now = datetime.datetime.now()
        try:
            doc = Vendors.objects.create(name =body['vendor'], address=body['address'],
                                         phone=body['phone'], tags=body['tags'],location=pt, registrationTime = now)
            doc.save()
        except Exception as e:
            return HttpResponse(json.dumps(self._makeReturn('FAIL','registerVendor', 'Failed on access to MongoDb  ------- ' + e.message)))

        timeMongoPut = datetime.datetime.now()
        performanceMessage += self._logGather('mongo put', timeMongoGet, timeMongoPut)

        # respond
        response = {}
        response['vendorId'] = doc.id
        response['coordinates'] = {}
        response['coordinates']['latitude'] = float(geocode['data']['lat'])
        response['coordinates']['longitude'] = float(geocode['data']['lng'])
        flat = json.dumps(self._makeReturn('OK', 'registerVendor', response))

        timeMadeResponse = datetime.datetime.now()
        performanceMessage += self._logGather('made response', timeMongoPut, timeMadeResponse)
        performanceMessage += self._logGather('total', timeEnterFunc, timeMadeResponse)
        self._doLog(level = 'DEBUG', cmd = performanceMessage)

        return HttpResponse(flat)

    def addTweet(self, request):
        performanceMessage = ''
        timeEnterFunc = datetime.datetime.now()

        # ingest request
        invalid = self._validateRequest(request)
        if invalid is not None:
            return HttpResponse(json.dumps(self._makeReturn('FAIL', 'addTweet', invalid)))
        self._doLog('DEBUG', 'addTweet', request.body)
        body = json.loads(request.body)

        timeGetVendor = datetime.datetime.now()
        performanceMessage += self._logGather('parsing request', timeEnterFunc, timeGetVendor)

        # get the vendor data from the vendors table in mongodb
        try:
            vendor = Vendors.objects.get(id = body['vendorId'])
        except Exception as e:
            return HttpResponse(json.dumps(self._makeReturn('FAIL','addTweet', 'vendorId <' + body['vendorId'] + '> is not registered')))

        timeGetTweet = datetime.datetime.now()
        performanceMessage += self._logGather('get vendor data', timeGetVendor, timeGetTweet)

        # find out if this vendor creates a new tweet or updates an existing one
        newTweet = False
        try:
            tweet = Tweets.objects.get(vendorId = body['vendorId'])
        except Exception as e:
            if type(e) is ServerSelectionTimeoutError:
                return HttpResponse(json.dumps(self._makeReturn('FAIL','addTweet', 'mongodb is down')))
            newTweet = True

        timeUpdateTweet = datetime.datetime.now()
        performanceMessage += self._logGather('try to get (if exists) tweet data', timeGetTweet, timeUpdateTweet)

        # create or update the tweet
        if newTweet:
            now = datetime.datetime.now()
            try:
                doc = Tweets.objects.create(message =body['tweet'], vendorId = body['vendorId'], vendorName = vendor.name, vendorAddress = vendor.address,
                                         vendorPhone = vendor.phone, vendorTags = vendor.tags, vendorLocation = vendor.location,
                                         creationTime = now, votes = 0)
                doc.save()
            except Exception as e:
                return HttpResponse(json.dumps(self._makeReturn('FAIL','addTweet', 'Failed on access to MongoDb  ------- ' + e.message)))
        else: # update
            try:
                tweet.message = body['tweet']
                tweet.votes = 0
                tweet.save()
            except Exception as e:
                return HttpResponse(json.dumps(self._makeReturn('FAIL','addTweet', 'Failed on access to MongoDb  ------- ' + e.message)))

        timeMakeResponse = datetime.datetime.now()
        performanceMessage += self._logGather('create (or update) tweet', timeUpdateTweet, timeMakeResponse)

        flat = json.dumps(self._makeReturn('OK', 'addTweet', 'OK'))

        timeExitFunc = datetime.datetime.now()
        performanceMessage += self._logGather('make response', timeMakeResponse, timeExitFunc)
        performanceMessage += self._logGather('total', timeEnterFunc, timeExitFunc)
        self._doLog(level = 'DEBUG', cmd = performanceMessage)

        return HttpResponse(flat)

    def getTweets(self, request):
        performanceMessage = ''
        timeEnterFunc = datetime.datetime.now()

        invalid = self._validateRequest(request)
        if invalid is not None:
            return HttpResponse(json.dumps(self._makeReturn('FAIL', 'getTweets', invalid)))
        self._doLog('DEBUG', 'getTweets', request.body)
        body = json.loads(request.body)

        patronTags = body['tags']
        maxDistance = int(body['radius'])
        lat = float(body['latitude'])
        lng = float(body['longitude'])
        query = { 'vendorLocation': { '$near': {'$geometry': {'type':"Point", 'coordinates': [lng, lat]}, '$maxDistance': maxDistance } } }

        timeQueryTweets = datetime.datetime.now()
        performanceMessage += self._logGather('parsing request', timeEnterFunc, timeQueryTweets)

        try:
            queryset = Tweets.objects.raw_query(query)
            n = len(queryset) # probably a Django MongoDB Engine issue. Empty queryset does not support the contract API
        except Exception as e:
            return HttpResponse(json.dumps(self._makeReturn('FAIL', 'getTweets', 'Failed on access to MongoDb  ------- ' + e.message)))

        timeMakeResponse = datetime.datetime.now()
        performanceMessage += self._logGather('get tweets inside radius', timeQueryTweets, timeMakeResponse)

        response = [self._responseTweet(q) for q in queryset if not self._filterByTag(patronTags, q.vendorTags)]
        flat = json.dumps(self._makeReturn('OK', 'getTweets', response))

        timeExitFunc = datetime.datetime.now()
        performanceMessage += self._logGather('make response', timeMakeResponse, timeExitFunc)
        performanceMessage += self._logGather('total', timeEnterFunc, timeExitFunc)
        self._doLog(level = 'DEBUG', cmd = performanceMessage)

        return HttpResponse(flat)

    def getVendorTweet(self, request):
        performanceMessage = ''
        timeEnterFunc = datetime.datetime.now()

        invalid = self._validateRequest(request)
        if invalid is not None:
            return HttpResponse(json.dumps(self._makeReturn('FAIL', 'getVendorTweet', invalid)))
        self._doLog('DEBUG', 'getVendorTwet', request.body)
        body = json.loads(request.body)
        vendorId = body['vendorId']

        timeGetVendorTweet = datetime.datetime.now()
        performanceMessage += self._logGather('parsing request', timeEnterFunc, timeGetVendorTweet)

        try:
            tweet = Tweets.objects.get(vendorId = vendorId)
        except Exception as e:
            return HttpResponse(json.dumps(self._makeReturn('FAIL','getVendorTweet', 'tweet for vendorId <' + vendorId + '> was not found.')))

        timeMakeResponse = datetime.datetime.now()
        performanceMessage += self._logGather('getVendorTweet', timeGetVendorTweet, timeMakeResponse)

        response = self._responseTweet(tweet)
        flat = json.dumps(self._makeReturn('OK', 'getVendorTweet', response))

        timeExitFunc = datetime.datetime.now()
        performanceMessage += self._logGather('make response', timeMakeResponse, timeExitFunc)
        performanceMessage += self._logGather('total', timeEnterFunc, timeExitFunc)
        self._doLog(level = 'DEBUG', cmd = performanceMessage)

        return HttpResponse(flat)

    def getAllVendorTweets(self, request):
        performanceMessage = ''
        timeEnterFunc = datetime.datetime.now()

        invalid = self._validateRequest(request)
        if invalid is not None:
            return HttpResponse(json.dumps(self._makeReturn('FAIL', 'getAllVendorTweets', invalid)))
        self._doLog('DEBUG', 'getAllVendorTweets', request.body)

        timeGetAllVendorTweets = datetime.datetime.now()
        performanceMessage += self._logGather('parsing request', timeEnterFunc, timeGetAllVendorTweets)

        try:
            queryset = Tweets.objects.all()
            n = len(queryset)
        except Exception as e:
            return HttpResponse(json.dumps(self._makeReturn('FAIL','timeGetAllVendorTweets', 'Failed on access to MongoDb  ------- ' + e.message)))

        timeMakeResponse = datetime.datetime.now()
        performanceMessage += self._logGather('getAllVendorTweets', timeGetAllVendorTweets, timeMakeResponse)

        response = self._responseAllTweets(queryset)
        flat = json.dumps(self._makeReturn('OK', 'getAllVendorTweets', response))

        timeExitFunc = datetime.datetime.now()
        performanceMessage += self._logGather('make response', timeMakeResponse, timeExitFunc)
        performanceMessage += self._logGather('total', timeEnterFunc, timeExitFunc)
        self._doLog(level = 'DEBUG', cmd = performanceMessage)

        return HttpResponse(flat)

    def getVendor(self, request):
        performanceMessage = ''
        timeEnterFunc = datetime.datetime.now()

        invalid = self._validateRequest(request)
        if invalid is not None:
            return HttpResponse(json.dumps(self._makeReturn('FAIL', 'getVendor', invalid)))
        self._doLog('DEBUG', 'getVendor', request.body)
        body = json.loads(request.body)
        vendorId = body['vendorId']

        timeGetVendor = datetime.datetime.now()
        performanceMessage += self._logGather('parsing request', timeEnterFunc, timeGetVendor)

        try:
            vendor = Vendors.objects.get(id = vendorId)
        except Exception as e:
            return HttpResponse(json.dumps(self._makeReturn('FAIL','getVendor', 'vendorId <' + body['vendorId'] + '> is not registered')))

        timeMakeResponse = datetime.datetime.now()
        performanceMessage += self._logGather('getVendor by id', timeGetVendor, timeMakeResponse)

        response = self._responseVendor(vendor)
        flat = json.dumps(self._makeReturn('OK', 'getVendor', response))

        timeExitFunc = datetime.datetime.now()
        performanceMessage += self._logGather('make response', timeMakeResponse, timeExitFunc)
        performanceMessage += self._logGather('total', timeEnterFunc, timeExitFunc)
        self._doLog(level = 'DEBUG', cmd = performanceMessage)

        return HttpResponse(flat)

    def getAllVendors(self, request):
        performanceMessage = ''
        timeEnterFunc = datetime.datetime.now()

        invalid = self._validateRequest(request)
        if invalid is not None:
            return HttpResponse(json.dumps(self._makeReturn('FAIL', 'getAllVendors', invalid)))
        self._doLog('DEBUG', 'getAllVendors', request.body)
        body = json.loads(request.body)

        timeGetAllVendors = datetime.datetime.now()
        performanceMessage += self._logGather('parsing request', timeEnterFunc, timeGetAllVendors)

        try:
            queryset = Vendors.objects.all()
            n = len(queryset)
        except Exception as e:
            return HttpResponse(json.dumps(self._makeReturn('FAIL','getAllVendors', 'Failed on access to MongoDb  ------- ' + e.message)))

        timeMakeResponse = datetime.datetime.now()
        performanceMessage += self._logGather('getAllVendors', timeGetAllVendors, timeMakeResponse)

        response = self._responseAllVendors(queryset)
        flat = json.dumps(self._makeReturn('OK', 'getAllVendors', response))

        timeExitFunc = datetime.datetime.now()
        performanceMessage += self._logGather('make response', timeMakeResponse, timeExitFunc)
        performanceMessage += self._logGather('total', timeEnterFunc, timeExitFunc)
        self._doLog(level = 'DEBUG', cmd = performanceMessage)

        return HttpResponse(flat)

    def upvote(self, request):
        performanceMessage = ''
        timeEnterFunc = datetime.datetime.now()

        # ingest request
        invalid = self._validateRequest(request)
        if invalid is not None:
            return HttpResponse(json.dumps(self._makeReturn('FAIL', 'upvote', invalid)))
        self._doLog('DEBUG', 'upvote', request.body)
        body = json.loads(request.body)
        vendorId = body['vendorId']

        timeGetVendor = datetime.datetime.now()
        performanceMessage += self._logGather('parsing request', timeEnterFunc, timeGetVendor)

        # get the vendor data from the vendors table in mongodb
        try:
            vendor = Vendors.objects.get(id = vendorId)
        except Exception as e:
            return HttpResponse(json.dumps(self._makeReturn('FAIL','upvote', 'vendorId <' + vendorId + '> is not registered')))

        timeGetTweet = datetime.datetime.now()
        performanceMessage += self._logGather('check that vendor exists', timeGetVendor, timeGetTweet)

        # get the tweet from mongo
        try:
            tweet = Tweets.objects.get(vendorId = vendorId)
        except Exception as e:
                return HttpResponse(json.dumps(self._makeReturn('FAIL','upvote', 'failed fetching the tweet:  ' + e.message)))

        timeUpdateTweet = datetime.datetime.now()
        performanceMessage += self._logGather('get tweet', timeGetTweet, timeUpdateTweet)

        try:
            tweet.votes +=1
            tweet.save()
        except Exception as e:
            return HttpResponse(json.dumps(self._makeReturn('FAIL','upvote', 'Failed on access to MongoDb  ------- ' + e.message)))

        timeMakeResponse = datetime.datetime.now()
        performanceMessage += self._logGather('update tweet', timeUpdateTweet, timeMakeResponse)

        flat = json.dumps(self._makeReturn('OK', 'upvote', 'OK'))

        timeExitFunc = datetime.datetime.now()
        performanceMessage += self._logGather('make response', timeMakeResponse, timeExitFunc)
        performanceMessage += self._logGather('total', timeEnterFunc, timeExitFunc)
        self._doLog(level = 'DEBUG', cmd = performanceMessage)

        return HttpResponse(flat)

    def downvote(self, request):
        performanceMessage = ''
        timeEnterFunc = datetime.datetime.now()

        # ingest request
        invalid = self._validateRequest(request)
        if invalid is not None:
            return HttpResponse(json.dumps(self._makeReturn('FAIL', 'downvote', invalid)))
        self._doLog('DEBUG', 'downvote', request.body)
        body = json.loads(request.body)
        vendorId = body['vendorId']

        timeGetVendor = datetime.datetime.now()
        performanceMessage += self._logGather('parsing request', timeEnterFunc, timeGetVendor)

        # get the vendor data from the vendors table in mongodb
        try:
            vendor = Vendors.objects.get(id = vendorId)
        except Exception as e:
            return HttpResponse(json.dumps(self._makeReturn('FAIL','downvote', 'vendorId <' + vendorId + '> is not registered')))

        timeGetTweet = datetime.datetime.now()
        performanceMessage += self._logGather('check that vendor exists', timeGetVendor, timeGetTweet)

        # get the tweet from mongo
        try:
            tweet = Tweets.objects.get(vendorId = vendorId)
        except Exception as e:
                return HttpResponse(json.dumps(self._makeReturn('FAIL','downvote', 'failed fetching the tweet:  ' + e.message)))

        timeUpdateTweet = datetime.datetime.now()
        performanceMessage += self._logGather('get tweet', timeGetTweet, timeUpdateTweet)

        try:
            tweet.votes -= 1
            tweet.save()
        except Exception as e:
            return HttpResponse(json.dumps(self._makeReturn('FAIL','downvote', 'Failed on access to MongoDb  ------- ' + e.message)))

        timeMakeResponse = datetime.datetime.now()
        performanceMessage += self._logGather('update tweet', timeUpdateTweet, timeMakeResponse)

        flat = json.dumps(self._makeReturn('OK', 'downvote', 'OK'))

        timeExitFunc = datetime.datetime.now()
        performanceMessage += self._logGather('make response', timeMakeResponse, timeExitFunc)
        performanceMessage += self._logGather('total', timeEnterFunc, timeExitFunc)
        self._doLog(level = 'DEBUG', cmd = performanceMessage)

        return HttpResponse(flat)

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
            Vendors.objects.all().delete()
            Tweets.objects.all().delete()
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
            return self._makeReturn('FAIL', cmd, 'google maps api - method geocode() failed:  ' + jsonObject['error_message'])

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

    def _doLog(self, level, cmd, msg = None):
        if msg is not None:
            fullMsg = "Request: " + cmd + '\n' + msg
        else:
            fullMsg = cmd

        if level == 'DEBUG':
            logger.debug(fullMsg)

    def _logGather(self, msg, start, end):
        duration = (end - start).microseconds/1000
        performance = 'start: %s end: %s -- delta: %d miliseconds' % (str(start), str(end), duration)
        fullMsg = '\n' + msg + ': ' + performance
        return fullMsg

    def _filterByTag(self, patronTags, vendorTags):
        if 'all' in patronTags:
            return False # do not filter
        for vndTag in vendorTags:
                if vndTag in patronTags:
                    return False # one vendor tag corresponds to a tag that interests the patron - that's enough
        return True # filter

    def _responseTweet(self, oneFromMongo):
        one = {}
        one['vendorId'] = oneFromMongo.vendorId
        one['name'] = oneFromMongo.vendorName
        one['address'] = oneFromMongo.vendorAddress
        one['phone'] = oneFromMongo.vendorPhone
        one['tags'] = oneFromMongo.vendorTags
        one['tweet'] = oneFromMongo.message
        one['coordinates'] = {'latitude':oneFromMongo.vendorLocation.coordinates[1], 'longitude':oneFromMongo.vendorLocation.coordinates[0]}
        one['creationTime'] = str(oneFromMongo.creationTime)
        one['votes'] = oneFromMongo.votes

        return one

    def _responseAllTweets(self, queryset):
        res = map(self._responseTweet, queryset)
        return res

    def _responseVendor(self, oneFromMongo):
        one = {}
        one['name'] = oneFromMongo.name
        one['address'] = oneFromMongo.address
        one['phone'] = oneFromMongo.phone
        one['coordinates'] = {'latitude':oneFromMongo.location.coordinates[1], 'longitude':oneFromMongo.location.coordinates[0]}
        one['tags'] = oneFromMongo.tags
        one['registrationTime'] = str(oneFromMongo.registrationTime)
        one['vendorId'] = oneFromMongo.id

        return one

    def _responseAllVendors(self, queryset):
        res = map(self._responseVendor, queryset)
        return res









