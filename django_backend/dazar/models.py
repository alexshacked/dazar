
from django.db import models
from djangotoolbox.fields import ListField
from djangotoolbox.fields import EmbeddedModelField
from django_mongodb_engine.contrib import MongoDBManager

class Point(models.Model):
    type = models.CharField(max_length=200)
    coordinates = ListField()

class Vendors(models.Model):
    name = models.CharField(max_length=200)
    address = models.CharField(max_length=200)
    phone = models.CharField(max_length=200)
    tags= ListField()
    location = EmbeddedModelField('Point')
    registrationTime = models.DateTimeField()

class Tweets(models.Model):
    message = models.CharField(max_length=200)
    vendorId = models.CharField(max_length=200)
    vendorName = models.CharField(max_length=200)
    vendorAddress = models.CharField(max_length=200)
    vendorPhone = models.CharField(max_length=200)
    vendorTags= ListField()
    vendorLocation = EmbeddedModelField('Point')
    creationTime = models.DateTimeField()
    votes = models.IntegerField()
    objects = MongoDBManager()

class Buyers(models.Model):
    buyerId = models.CharField(max_length=200)
    buyerLocation  = EmbeddedModelField('Point')
    buyerTags= ListField()
    creationTime = models.DateTimeField(auto_now=True, auto_now_add=True)
    objects = MongoDBManager()

class PseudoBuyers(models.Model):
    buyerId = models.CharField(max_length=200)
    buyerLocation  = EmbeddedModelField('Point')
    buyerTags= ListField()
    creationTime = models.DateTimeField()
    objects = MongoDBManager()

class Locations(models.Model):
    address = models.CharField(max_length=200)
    point = EmbeddedModelField('Point')
    objects = MongoDBManager()