from django.http import HttpResponse
from models import Tweets

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