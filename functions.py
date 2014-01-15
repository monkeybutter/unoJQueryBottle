import datetime, math, string, json, bson, time, pytz
import numpy as np
import pylab as pl
from pymongo import Connection
from bson.json_util import dumps

class DataTransformer():

    def getCursorY(self, dateRange, Yname):

        connection = Connection('localhost', 27017)
        db = connection.solarPod

        rangeList = dateRange.split()

        string1 = rangeList[0].split('/')
        string2 = rangeList[2].split('/')

        #start = datetime.datetime(int(string1[2]), int(string1[1]), int(string1[0]), 2)
        #end = datetime.datetime(int(string2[2]), int(string2[1]), int(string2[0]), 2)
        start = datetime.datetime(int(string1[2]), int(string1[1]), int(string1[0]))
        end = datetime.datetime(int(string2[2]), int(string2[1]), int(string2[0]))

        print dateRange
        print start.strftime("%Y-%m-%d %H:%M:%S")
        print end.strftime("%Y-%m-%d %H:%M:%S")
        print "??????????????????????????"

        varY = "data." + Yname

        obs = connection.solarPod.obs
        return obs.find({"name" : "Black Mountain", "date" : {'$gte': start, '$lt': end}}, { varY : 1, "date" : 1, "_id" : 0})


    def getCursorX(self, dateRange, Xnames):

        connection = Connection('localhost', 27017)
        db = connection.solarPod

        rangeList = dateRange.split()

        string1 = rangeList[0].split('/')
        string2 = rangeList[2].split('/')

        #start = datetime.datetime(int(string1[2]), int(string1[1]), int(string1[0]), 2)
        #end = datetime.datetime(int(string2[2]), int(string2[1]), int(string2[0]), 2)
        start = datetime.datetime(int(string1[2]), int(string1[1]), int(string1[0]))
        end = datetime.datetime(int(string2[2]), int(string2[1]), int(string2[0]))

        pred = connection.solarPod.access
        result = []

        for Xname in Xnames:
            varX = "data." + Xname + ".value"
            result.append(pred.find({"name" : "ACCESS-BM01", "date" : {'$gte': start, '$lt': end}}, { varX : 1, "date" : 1, "_id" : 0}))

        return result

    # cursorY is a mongoDB cursor and cursorX is list of cursors
    def getXY(self, cursorsX, Xnames, cursorY, Yname):

        # Lists with data
        listsPred = list()
        for cursorX in cursorsX:
                listsPred.append(list())
        listObs = list()
        listDate = list()

        # Read from MongoDB cursors and write in lists for the same dates
        try:
            itemsPred = list()
            for cursorX in cursorsX:
                itemsPred.append(cursorX.next())
            itemObs = cursorY.next()

        except StopIteration:
            print 'Exception at first line'

        datesPred = list()
        for itemPred in itemsPred:
            datesPred.append(itemPred['date'])
        dateObs = itemObs['date']

        while True:
            if ((datesPred[0] - dateObs).seconds < 0):
                try:
                    del itemsPred[:]
                    for cursorX in cursorsX:
                        itemsPred.append(cursorX.next())

                except StopIteration:
                    break

                del datesPred[:]
                for itemPred in itemsPred:
                    datesPred.append(itemPred['date'])

            elif ((datesPred[0] - dateObs).seconds > 0):
                try:
                    itemObs = cursorY.next()
                except StopIteration:
                    break
                dateObs = itemObs['date']

            else:

                exists = True

                if (math.isnan(itemObs['data'][Yname])):
                    exists = False

                for index in range(0, len(cursorsX)):
                    if (math.isnan(itemsPred[index]['data'][Xnames[index]][0]['value'])):
                        exists = False

                if (exists):
                    listDate.append(itemObs['date'])
                    listObs.append(itemObs['data'][Yname])
                    for index in range(0, len(cursorsX)):
                        listsPred[index].append(itemsPred[index]['data'][Xnames[index]][0]['value'])


                try:
                    del itemsPred[:]
                    for cursorX in cursorsX:
                        itemsPred.append(cursorX.next())
                    itemObs = cursorY.next()

                except StopIteration:
                    break

                del datesPred[:]
                for itemPred in itemsPred:
                    datesPred.append(itemPred['date'])
                dateObs = itemObs['date']

        # Modify data into sci-kit learn format
        listPred = np.array(zip(*listsPred))
        listObs = np.array(listObs)
        listDate = np.array(listDate)

        return listDate, listObs, listPred


class ClearSky():
    def getDirectRad(self, date):

        connection = Connection('localhost', 27017)
        clearsky = connection.solarPod.clearsky

        obj = clearsky.find_one({"name":"Black Mountain", "date":date})

        return obj["data"]["DHI"]


    def getYData(self, dateRange, Yname):

        connection = Connection('localhost', 27017)
        obs = connection.solarPod.obs

        rangeList = dateRange.split()

        string1 = rangeList[0].split('/')
        string2 = rangeList[2].split('/')

        #startDate = datetime.datetime(int(string1[2]), int(string1[1]), int(string1[0]), 2)
        #endDate = datetime.datetime(int(string2[2]), int(string2[1]), int(string2[0]), 2)
        startDate = datetime.datetime(int(string1[2]), int(string1[1]), int(string1[0]))
        endDate = datetime.datetime(int(string2[2]), int(string2[1]), int(string2[0]))

        varY = "$data." + Yname

        obj = obs.aggregate([ { '$match' : { 'name' : "Black Mountain", 'date' : {'$gte': startDate, '$lt': endDate} }}, { '$project' : { 'date' : 1 , 'y' : varY , '_id' : 0}}, { '$sort' : { 'date' : 1 }} ])
        
        return dumps(obj["result"])
        
class CustomEncoder(json.JSONEncoder):
    def default(self, obj):
        if isinstance(obj, bson.objectid.ObjectId):
            return str(obj)
        elif isinstance(obj, datetime.datetime):
            return obj.isoformat()
        return json.JSONEncoder.default(self, obj)