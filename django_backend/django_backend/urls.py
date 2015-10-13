from django.conf.urls import patterns, include, url
from dazar.views import DazarAPI

# Uncomment the next two lines to enable the admin:
# from django.contrib import admin
# admin.autodiscover()

api = DazarAPI()
urlpatterns = patterns('',
    url(r'^registerVendor$', api.registerVendor),
    url(r'^addTweet$', api.addTweet),
    url(r'^getTweets$', api.getTweets),
    url(r'^getCoordinates$', api.debugGetCoordinates),
    url(r'^addAddress$', api.debugAddAddress),
    url(r'^neighbours$', api.debugNeighbours),
    url(r'^all$', api.debugAll),
    url(r'^truncate$', api.debugTruncate),
    url(r'^gisUnittest$', api.debugGisUnittest),
    url(r'^apiConsole$', api.debugApiConsole),
)

