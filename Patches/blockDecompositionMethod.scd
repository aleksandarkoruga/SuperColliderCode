//block decomposition method
//https://www.complexitycalculator.com/DownloadDataAndTools.html
//https://github.com/algorithmicnaturelab
//https://arxiv.org/pdf/1609.00110v2.pdf


~complexities= FileReader.read("/complexities.txt",true,true,delimiter:'\n').asFloat.flat;



//complexities are symmetrical..
a= ~complexities[(0..(~complexities.size/2-1))];
b= ~complexities[((~complexities.size/2)..(~complexities.size-1))];
b=b.reverse;
a.plot;
b.plot;
a==b;



(//16 bit maximum block size.
var patternToTest=[1,1,0,1,1,1,0,0,0,0,0,0,0,1,0,1];
var bdmFunc;
var blockSize=4; // can be any subdivision (length clipped inside function)

patternToTest=patternToTest.convertDigits(2);
//patternToTest.postln;

//or use just int number
patternToTest=4245734;

bdmFunc={|n,blockSize,ctmList|

	var bD=n.asBinaryDigits;
	var histArray;
	var bdm=0;
	blockSize=blockSize.clip(1,bD.size.clip(1,16));

	histArray= Bag.new( (2.pow(blockSize)));

	(bD.size-blockSize).do({|item,i|
		var subS=bD[i..(i+(blockSize-1))];

		histArray.add(subS.convertDigits(2));

	});

	histArray.contents.keysValuesDo({ |key, value|
		//do BDM

		var val;
		val= ctmList[key];

		bdm=bdm+val+value.log2;

	});
bdm
};
bdmFunc.value(patternToTest,5,~complexities)
)



