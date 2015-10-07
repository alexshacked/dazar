from django.conf.urls import patterns, include, url
from dazar.views import addAddress
from dazar.views import neighbours
from dazar.views import all
from dazar.views import truncate
from dazar.views import gisUnittest

# Uncomment the next two lines to enable the admin:
# from django.contrib import admin
# admin.autodiscover()

urlpatterns = patterns('',
    url(r'^addAddress$', addAddress),
    url(r'^neighbours$', neighbours),
    url(r'^all$', all),
    url(r'^truncate$', truncate),
    url(r'^gisUnittest$', gisUnittest),
)

