/*
 * (C) 2015 Finn Arild Aasheim, Fluido Oy. No liabilities accepted.
 *
 * Advanced math class, started on the base of http://www.jonathanbroquist.com/calculating-standard-deviations-with-salesforce/
 * 
 * Improved by myself by overriding it with an avg variable if you already have that (to save some looping)
 */
public with sharing class AdvancedMath {


	public static Double standardDeviation(Double[] numbers) {
		//determine the sum of the range of numbers
		Double sum = 0;
		for(Double d : numbers)
		{
			sum += d;
		}

		//determine the mean of the range of numbers
		Double mean = sum / numbers.size();

		return standardDeviation(numbers, mean);		
	}

	public static Double standardDeviation(Double[] numbers, Double mean)
	{

		//for each number subtract the mean and square the result
		Double squaredDifferencesSum = 0;
		for(Double d : numbers)
		{
			squaredDifferencesSum += Math.pow((d-mean), 2);
		}

		//determine the mean for the squared differences
		Double squaredDifferencesMean = squaredDifferencesSum / numbers.size();

		//determine the standard deviation
		Double standardDeviation = Math.sqrt(squaredDifferencesMean);

		return standardDeviation;
	}

}