from django.conf.urls import patterns, include, url
from dazar.views import addAddress
from dazar.views import neighbours

# Uncomment the next two lines to enable the admin:
# from django.contrib import admin
# admin.autodiscover()

urlpatterns = patterns('',
    url(r'^addAddress$', addAddress),
    url(r'^neighbours$', neighbours),
)

