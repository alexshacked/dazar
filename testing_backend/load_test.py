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

    def performance(self, street, start, end):
        durationTotal = (end - start).seconds
        durationOne = (durationTotal * 1000) / street[2]
        msg = 'Processing street: %s took %d seconds. %d miliseconds per address\n' % (street[0], durationTotal, durationOne)
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

        return resp, js

    def doTruncate(self):
        req = urllib2.Request(url = self.TRUNCATE_URI)
        fromWire = urllib2.urlopen(req).read()

        resp = json.loads(fromWire)
        return resp['status']

    def start(self):
        streets = [['ibn gvirol, tel aviv', 1, 200], ['dizengoff, tel aviv', 1, 200], ['hayarkon, tel aviv', 1, 300],
                    ['derech namir, tel aviv', 1, 200], ['alenby, tel aviv', 1, 130]]

        didTrunk = self.doTruncate()
        self.doLog('Clean database: ' + didTrunk)

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
            self.performance(street, start, end)

        self.doLog('End registration')




tester = LoadTest()
tester.start()