from django.conf.urls import patterns, include, url
from dazar.views import getComments
from dazar.views import putComment

# Uncomment the next two lines to enable the admin:
# from django.contrib import admin
# admin.autodiscover()

urlpatterns = patterns('',
    url(r'^get$', getComments),
    url(r'^put$', putComment),
)

