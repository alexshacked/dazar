from django.conf.urls import patterns, include, url
from dazar.views import getComments
from dazar.views import putComment
from dazar.views import addAddress
from dazar.views import neighbours

# Uncomment the next two lines to enable the admin:
# from django.contrib import admin
# admin.autodiscover()

urlpatterns = patterns('',
    url(r'^get$', getComments),
    url(r'^put$', putComment),
    url(r'^addAddress$', addAddress),
    url(r'^neighbours$', neighbours),
)

