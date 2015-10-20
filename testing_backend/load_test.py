import urllib2
import json
import datetime


class LoadTest:
    def __init__(self):
        self.BASE_URI = "http://dazar.io/"
        self.REGISTER_URI = self.BASE_URI + 'registerVendor'
        self.ADD_URI = self.BASE_URI + 'addTweet'
        self.GET_URI = self.BASE_URI + 'getTweets'
        self.TRUNCATE_URI = self.BASE_URI + 'truncate'

        self.log = open('./report.txt', 'w')

        self.vendors = []

    def doLog(self, msg):
        now = datetime.datetime.now()
        strNow = str(now)
        final = strNow + ':   ' + msg
        self.log.write(final)
        print final

    def performance(self, message, size, start, end):
        durationTotal = (end - start).seconds
        durationOne = (durationTotal * 1000) / size
        msg = 'Processing %s: took %d seconds. %d miliseconds per unit\n' % (message, durationTotal, durationOne)
        self.doLog(msg)


    def doRegisterVendor(self, vendor, address, phone, tags):
        js = {"vendor": vendor,
              "address": address,
              "phone": phone,
              "tags": tags}

        flat = json.dumps(js)
        req = urllib2.Request(url = self.REGISTER_URI, data = flat)
        fromWire = urllib2.urlopen(req).read()
        resp = json.loads(fromWire)
        if resp['status'] == 'OK':
            js['id'] = resp['data']['vendorId']
            js['coordinates'] = resp['data']['coordinates']

        return resp, js

    def doTweet(self, vendor):
        js = {'vendorId': vendor['id'],
              'tweet': vendor['vendor'] + ' is tweeting right now!'}
        flat = json.dumps(js)
        req = urllib2.Request(url = self.ADD_URI, data = flat)
        fromWire = urllib2.urlopen(req).read()
        resp = json.loads(fromWire)

        return resp

    def doQueryTweets(self, vendor, radius = 300):
        js = {'latitude': vendor['coordinates']['latitude'],
              'longitude': vendor['coordinates']['longitude'],
              'radius': radius,
              'tags': vendor['tags']}

        flat = json.dumps(js)
        req = urllib2.Request(url = self.GET_URI, data = flat)
        fromWire = urllib2.urlopen(req).read()
        resp = json.loads(fromWire)

        return resp

    def doTruncate(self):
        req = urllib2.Request(url = self.TRUNCATE_URI)
        fromWire = urllib2.urlopen(req).read()

        resp = json.loads(fromWire)
        return resp['status']

    def start(self):
        '''
        streets = [['ibn gvirol, tel aviv', 1, 200], ['dizengoff, tel aviv', 1, 200], ['hayarkon, tel aviv', 1, 300],
                    ['derech namir, tel aviv', 1, 200], ['alenby, tel aviv', 1, 130]]
        '''
        streets = [['ibn gvirol, tel aviv', 1, 5], ['dizengoff, tel aviv', 1, 5]]
        didTrunk = self.doTruncate()
        self.doLog('Clean database: ' + didTrunk)

        # registration
        self.doLog('Start registration\n')
        idx = 1
        for street in streets:
            start = datetime.datetime.now()
            self.doLog('Beginning to work on street: ' + street[0])

            for i in range(street[1], street[2]):
                store = 'store ' + str(idx)
                address = str(i) + ' ' + street[0]
                telephone = str(123456789 + idx)
                tags = ['cafes']
                idx = idx + 1
                resp, js = self.doRegisterVendor(store, address, telephone, tags)
                if resp['status'] == 'FAIL':
                    self.doLog(resp['info'])
                else:
                    self.vendors.append(js)

            end = datetime.datetime.now()
            self.performance('street ' + street[0], street[2], start, end)

        self.doLog('End registration')

        # tweet
        self.doLog('Start tweeting\n')
        start = datetime.datetime.now()
        for vendor in self.vendors:
            resp = self.doTweet(vendor)
            if resp['status'] == 'FAIL':
                self.doLog(resp['info'])

        end = datetime.datetime.now()
        self.performance('tweeting from all vendors', len(self.vendors), start, end)

        # getTweets
        self.doLog('Start querying tweets\n')
        start = datetime.datetime.now()
        for vendor in self.vendors:
            resp = self.doQueryTweets(vendor)
            if resp['status'] == 'FAIL':
                self.doLog(resp['info'])

        end = datetime.datetime.now()
        self.performance('tweeting from all vendors', len(self.vendors), start, end)




########################################### driver #################################################
tester = LoadTest()
tester.start()