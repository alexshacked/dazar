from django.http import HttpResponse
from models import Tweets
from models import Locations
from models import Point
# from geojson import Point

import re
import urllib2
import json

def getComments(request):
    ret = Tweets.objects.all()
    s = ''
    for r in ret:
        s += r.user
        s += ' '
    return HttpResponse(s)

def putComment(request):
    user = request.GET['user']
    comment = request.GET['comment']
    try:
        tweet = Tweets.objects.get(user=user)
    except Tweets.DoesNotExist:
        tweet = Tweets.objects.create(user=user, comments=[comment])
    else:
        tweet.comments.append(comment)
    tweet.save()
    return  HttpResponse(user + ' ' + comment)

def geocodeFromGoogle(civil_addr):
    start = 'https://maps.googleapis.com/maps/api/geocode/json?address='
    mid = civil_addr
    end = '&key=AIzaSyAQ_Qt1ohwtRK84fy18fUpYllL0sZhX0wo'
    uri = start + mid + end

    geocode = urllib2.urlopen(uri).read()
    jsonObject = json.loads(geocode)
    coords = jsonObject['results'][0]['geometry']['location']

    return coords

def extractAddress(request):
    initial_addr = request.GET['addr']
    formatted_addr = re.sub(r'[ ]+', '+', initial_addr)
    return initial_addr, formatted_addr

def addAddress(request):
    initial_addr, formatted_addr = extractAddress(request)
    geocode = geocodeFromGoogle(formatted_addr)

    pt = Point(type = 'Point', coordinates = [float(geocode['lat']), float(geocode['lng'])] )

    doc = Locations.objects.create(address=initial_addr, point=pt)
    doc.save()
    return HttpResponse('ok')

def neighbours(request):
    initial_addr, formatted_addr = extractAddress(request)
    geocode = geocodeFromGoogle(formatted_addr)

    maxDistance = int(request.GET['radius'])
    lat = float(geocode['lat'])
    lng = float(geocode['lng'])
    query = { 'point': { '$near': {'$geometry': {'type':"Point", 'coordinates': [lat, lng]}, '$maxDistance': maxDistance } } }

    queryset = Locations.objects.raw_query(query)
    try:
        n = len(queryset) # probably a Django MongoDB Engine issue. Empty queryset does not support the contract API
    except:
        return HttpResponse('none')

    res = {}
    res['result'] = []
    for q in queryset:
        store = {}
        store['address'] = q.address
        store['coordinates'] = q.point.coordinates
        res['result'].append(store)

    return HttpResponse(json.dumps(res))
