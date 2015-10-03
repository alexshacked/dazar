
from django.db import models
from djangotoolbox.fields import ListField
from djangotoolbox.fields import EmbeddedModelField
from django_mongodb_engine.contrib import MongoDBManager

class Tweets(models.Model):
    user = models.CharField(max_length=200)
    comments = ListField()

class Point(models.Model):
    type = models.CharField(max_length=200)
    coordinates = ListField()

class Locations(models.Model):
    address = models.CharField(max_length=200)
    point = EmbeddedModelField('Point')
    objects = MongoDBManager()