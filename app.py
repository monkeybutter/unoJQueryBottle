from functions import DataTransformer, CustomEncoder, ClearSky
from bottle import route, run, template, request, static_file
from sklearn import datasets, linear_model, ensemble, svm
from bson.json_util import dumps
import datetime, json, pytz
import numpy, math
import numpy as np
import pylab as pl

enc = CustomEncoder()
trans = DataTransformer()
csk = ClearSky()

@route('/js/d3.v3.js')
def server_static():
    return static_file('d3.v3.js', root='bootstrap/js')

@route('/css/bootstrap.min.css')
def server_static():
    return static_file('bootstrap.min.css', root='bootstrap/css')

@route('/js/bootstrap.min.js')
def server_static():
    return static_file('bootstrap.min.js', root='bootstrap/js')

@route('/favicon.ico')
def get_favicon():
	return static_file('favicon.ico', root='static/')

@route('/home')
def hello():
	return template('template')

@route('/home', method='POST')
def helloPost():
	obj = request.json

	trainObsCursor = trans.getCursorY(obj["train"], obj["Y"])
	trainPredCursors = trans.getCursorX(obj["train"], obj["X"])

	trainDateDataset, trainObsDataset, trainPredDataset = trans.getXY(trainPredCursors, obj["X"], trainObsCursor, obj["Y"])
	print "------------------"
	print trainDateDataset[0]
	print trainDateDataset[1]
	print trainDateDataset[2]
	print trainDateDataset[3]
	print trainDateDataset[4]
	print "------------------"
	testObsCursor = trans.getCursorY(obj["test"], obj["Y"])
	testPredCursors = trans.getCursorX(obj["test"], obj["X"])

	testDateDataset, testObsDataset, testPredDataset = trans.getXY(testPredCursors, obj["X"], testObsCursor, obj["Y"])

	rmse = 0
	mae = 0
	forecastedValues = []

	if (obj["alg"] == "lr"):

		print "Linear Regression"
		# Create linear regression object
		regr = linear_model.LinearRegression()
		# Train the linear model using the training sets
		regr.fit(trainPredDataset, trainObsDataset)
		# The coefficients
		print 'Linear Coefficients: \n', regr.coef_

		forecastedValues = regr.predict(testPredDataset)

		print len(forecastedValues)
		print type(forecastedValues)
		print len(testPredDataset)
		print type(testPredDataset)

		print forecastedValues[0]
		print testPredDataset[0]

		rmseAcum = 0
		maeAcum = 0

		for number in range(len(forecastedValues)):
			rmseAcum += (forecastedValues[number] - testObsDataset[number]) ** 2
			maeAcum += (forecastedValues[number] - testObsDataset[number])

		rmse = (rmseAcum/len(forecastedValues)) ** 0.5
		mae = (maeAcum/len(forecastedValues))

		print ('Variance score (linear): %.2f' % regr.score(testPredDataset, testObsDataset))


	elif (obj["alg"] == "rf"):
		print "Random Forest"
		# Create Random Forest Regressor
		rfr = ensemble.RandomForestRegressor(n_estimators=10, criterion='mse', max_depth=None, min_samples_split=2, min_samples_leaf=1, min_density=0.1, max_features='auto', bootstrap=True, compute_importances=False, oob_score=False, n_jobs=1, random_state=None, verbose=0)
		# Train the forest model using the training sets
		rfr.fit(trainPredDataset, trainObsDataset)
		print 'Forest Coefficients: \n', rfr.estimators_

		forecastedValues = rfr.predict(testPredDataset)

		rmseAcum = 0
		maeAcum = 0

		for number in range(len(forecastedValues)):
			rmseAcum += (forecastedValues[number] - testObsDataset[number]) ** 2
			maeAcum += (forecastedValues[number] - testObsDataset[number])

		rmse = (rmseAcum/len(forecastedValues)) ** 0.5
		mae = (maeAcum/len(forecastedValues))

		print ('Variance score (forest): %.2f' % rfr.score(testPredDataset, testObsDataset))


	elif (obj["alg"] == "br"):
		print "Bayesian Ridge Regression"
		# Create a Bayesian Ridge Regressor
		clf = linear_model.BayesianRidge()

		# Train the forest model using the training sets
		clf.fit(trainPredDataset, trainObsDataset)
		print 'Bayesian Regression Coefficients: \n', clf.coef_

		forecastedValues = clf.predict(testPredDataset)

		rmseAcum = 0
		maeAcum = 0

		for number in range(len(forecastedValues)):
			rmseAcum += (forecastedValues[number] - testObsDataset[number]) ** 2
			maeAcum += (forecastedValues[number] - testObsDataset[number])

		rmse = (rmseAcum/len(forecastedValues)) ** 0.5
		mae = (maeAcum/len(forecastedValues))


	elif (obj["alg"] == "ar"):
		print "Auto Regression"

		for i in range(len(testPredDataset)):
			if (i == 0):
				forecastedValues.append(testPredDataset[0])
			else:
				if (testObsDataset[i-1]<5.0):
					forecastedValues.append(testPredDataset[i])
				else:
					factor = testObsDataset[i-1]/testPredDataset[i-1]
					if (factor < 0.33):
						forecastedValues.append(0.33*testPredDataset[i])
					elif (factor > 3):
						if (3.0*testPredDataset[i] > csk.getDirectRad(testDateDataset[i])):
							forecastedValues.append(csk.getDirectRad(testDateDataset[i]))
						else:
							forecastedValues.append(3.0*testPredDataset[i])
					else:
						if (factor*testPredDataset[i]>csk.getDirectRad(testDateDataset[i])):
							forecastedValues.append(csk.getDirectRad(testDateDataset[i]))
							#forecastedValues.append(factor*testPredDataset[i])
						else:
							forecastedValues.append(factor*testPredDataset[i])


		forecastedValues = np.asarray(forecastedValues)

		for i in range(len(testPredDataset)):
			print 'Date: ' + testDateDataset[i].strftime("%Y-%m-%dT%H:%M:%S.Z")
			print ('Model Value: %.2f' % testPredDataset[i])
			print ('Adjusted Value: %.2f' % forecastedValues[i])
			print ('Observed Value: %.2f' % testObsDataset[i])

		rmseAcum = 0
		maeAcum = 0

		for number in range(len(forecastedValues)):
			rmseAcum += int((forecastedValues[number] - testObsDataset[number]) ** 2)
			maeAcum += (forecastedValues[number] - testObsDataset[number])

		rmse = (rmseAcum/len(forecastedValues)) ** 0.5
		mae = (maeAcum/len(forecastedValues))

	elif (obj["alg"] == "rar"):
		print "Regression + Auto Regression"

		regr = linear_model.LinearRegression()
		# Train the linear model using the training sets
		regr.fit(trainPredDataset, trainObsDataset)
		# The coefficients
		print 'Linear Coefficients: \n', regr.coef_

		regressedValues = regr.predict(testPredDataset)

		print "Regression done!!!"

		for i in range(len(regressedValues)):
			if (i == 0):
				forecastedValues.append(regressedValues[0])
			else:
				if (testObsDataset[i-1]<5.0):
					forecastedValues.append(regressedValues[i])
				else:
					clearSky = csk.getDirectRad(testDateDataset[i])
					factor = testObsDataset[i-1]/regressedValues[i-1]
					if (factor < 0.33):
						forecastedValues.append(0.33*regressedValues[i])
					elif (factor > 3):
						if (3.0*regressedValues[i] > clearSky):
							forecastedValues.append(clearSky)
						else:
							forecastedValues.append(3.0*regressedValues[i])
					else:
						if (factor*regressedValues[i]>clearSky):
							forecastedValues.append(csk.getDirectRad(testDateDataset[i]))
							#forecastedValues.append(factor*testPredDataset[i])
						else:
							forecastedValues.append(factor*regressedValues[i])


		forecastedValues = np.asarray(forecastedValues)

		rmseAcum = 0
		maeAcum = 0
		
		for number in range(len(forecastedValues)):
			rmseAcum += int((forecastedValues[number] - testObsDataset[number]) ** 2)
			maeAcum += (forecastedValues[number] - testObsDataset[number])

		rmse = (rmseAcum/len(forecastedValues)) ** 0.5
		mae = (maeAcum/len(forecastedValues))

	elif (obj["alg"] == "oo"):
		print "Model Error"

		rmseAcum = 0
		maeAcum = 0

		for number in range(len(testPredDataset)):
			rmseAcum += (testPredDataset[number][0] - testObsDataset[number]) ** 2
			maeAcum += (testPredDataset[number][0] - testObsDataset[number])

		rmse = (rmseAcum/len(testPredDataset)) ** 0.5
		mae = maeAcum/len(testPredDataset)

	mydecoder = json.JSONDecoder()
	YData = csk.getYData(obj["test"], obj["Y"])
	plotData = []

	i = 0
	for part in mydecoder.decode(YData): 

		partDate = datetime.datetime.fromtimestamp(part["date"]["$date"]/1000, tz=pytz.utc)
		partDate = partDate.replace(tzinfo=None)

		if (i>=len(testDateDataset)):
			break

		else:
			while (testDateDataset[i] < partDate):
				i+=1
				if (i>=len(testDateDataset)):
					break
			if (testDateDataset[i] > partDate):
				print "Do nothing"
			elif (testDateDataset[i] == partDate):
				plotData.append({"date":partDate.strftime("%s"), "Y":part["y"], "Pred":forecastedValues[i]})   
			i+=1                                

	listOut = {}
	listOut['rmse'] = rmse
	listOut['mae'] = mae
	listOut['plotData'] = plotData

	return listOut

run(host='localhost', port=8080, debug=True, reloader=True)