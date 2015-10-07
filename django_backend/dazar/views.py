from django.http import HttpResponse
from django.template.loader import get_template
from django.template import Context
from models import Locations
from models import Point

import re
import urllib2
import json

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

# API
def addAddress(request):
    initial_addr, formatted_addr = extractAddress(request)
    geocode = geocodeFromGoogle(formatted_addr)

    pt = Point(type = 'Point', coordinates = [float(geocode['lng']), float(geocode['lat'])] )

    doc = Locations.objects.create(address=initial_addr, point=pt)
    doc.save()
    return HttpResponse('ok')

def parseMongoResponse(queryset):
    res = {}
    res['result'] = []
    for q in queryset:
        store = {}
        store['address'] = q.address
        store['coordinates'] = {'latitude':q.point.coordinates[1], 'longitude':q.point.coordinates[0]}
        res['result'].append(store)

    return json.dumps(res)

# API
def neighbours(request):
    initial_addr, formatted_addr = extractAddress(request)
    geocode = geocodeFromGoogle(formatted_addr)

    maxDistance = int(request.GET['radius'])
    lat = float(geocode['lat'])
    lng = float(geocode['lng'])
    query = { 'point': { '$near': {'$geometry': {'type':"Point", 'coordinates': [lng, lat]}, '$maxDistance': maxDistance } } }

    queryset = Locations.objects.raw_query(query)
    try:
        n = len(queryset) # probably a Django MongoDB Engine issue. Empty queryset does not support the contract API
    except:
        return HttpResponse('none')

    res = parseMongoResponse(queryset);
    return HttpResponse(res)

# API
def all(request):
    queryset = Locations.objects.all()
    res = parseMongoResponse(queryset);
    return HttpResponse(res)

# API
def truncate(request):
    Locations.objects.all().delete()
    return HttpResponse('ok')

# API
def gisUnittest(request):
    t = get_template('gisUnittest.html')
    html = t.render( Context({}) )
    return HttpResponse(html)






