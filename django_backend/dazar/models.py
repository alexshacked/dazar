
from django.db import models
from djangotoolbox.fields import ListField


class Tweets(models.Model):
    user = models.CharField(max_length=200)
    comments = ListField()