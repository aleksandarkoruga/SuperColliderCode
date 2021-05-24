

// keep= [ [base,[levels]],... ]
// keep= [ [2,[\full]],[3,[\alloperiodic]]   ]
//ANALYSIS
//full,periodic,alloperiodic,one



~weightFunc.value([ 1, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 ],2)

(


~periodicityHisto={
	|patternIn|
	var out=[];
	var full=[],periodic=[],alloperiodic=[],one=[];
	//bases>2 make sense 0,1,2 eliminated

	var maxIter=(patternIn.size()-2);
	maxIter.do({|baseIter|


	var base=baseIter+2;

	var pattern= NumericalExtensions.toBinaryArray( ~weightFunc.value(patternIn.postln,base.postln).floor,patternIn.size) ;


		var length=pattern.size();
	var n=(length/base).asInteger;
	var mod=(length%base).asInteger;
	var mask= ((0!(length-base))++(1!base));
		"length".post;
		length.post;
		"base".post;
		base.post;
		"".postln;
		pattern.postln;

	(1+mod).do({ |ii|
		var i=ii;

		n.do({
			|j|





			// retreive if level full, periodic or aperiodic

		var locMask=((mask).rotate(( (-1*i) -(j*base)).asInteger));
		var filtered=(locMask*pattern);
		var nBits=filtered.sum;
		var idx=locMask.find([1]);


		switch(nBits.asInteger,
				base,{/*all bits on-level full*/full=full.add([base,idx])},
				0,{/*do nothing*/},
				1,{/*only one bit on*/ one= one.add([base,idx])},
				/*default-m bits active*/
				{/*control if periodic-alloperiodic*/
				if(filtered.find([1,1])!=nil,
						{/*periodic*/periodic=periodic.add([base,idx])  },
						{/*alloperiodic*/alloperiodic=alloperiodic.add([base,idx])})
			});



			// save coordinate if masked pattern contains periodicities or aperiodic ()



			//var ~revWeightFunc.value(NumericalExtensions.convertDigitsFloat(locMask,2),length,base).convertDigits(2).postln;


		});

	})
});
	out=[full,periodic,alloperiodic,one];

};



~testPeriod={
|inPattern,keep,varOffset|
var pattern=inPattern;
var types=[\full,\periodic,\alloperiodic,\one];
var histo=~periodicityHisto.value(pattern);
var filteredHisto;
var pat=(0!(pattern.size));//b=pat
// filter from keep variable the bases and levels necessary
	//histo.postln;
	keep=histo.collect({|item,i|[item.flop[0].histo(~patternLength,0,~patternLength).maxIndex,types[i]]});

	keep=keep.flop;


	keep[0].do({
		|level,i|

		var keepIdx=i;
		filteredHisto=histo.deepCopy;

		filteredHisto.collect({|item|item.removeAllSuchThat({|item| item[0]!=level})});

		filteredHisto.do({|item,i|

			//0 full,1 periodic,2 alloperiodic, 3 one

			if(i==types.indexOf(keep[1].at(keepIdx))/*specify which category to keep*/,{

	item.do({ |item|
	var base=item[0];
	var idx=item[1];

	var mask= (0!(idx))++(1!(base))++(0!(pattern.size-base-idx)) ;

	var patternW;

	patternW=NumericalExtensions.toBinaryArray(~weightFunc.value(pattern,base).floor,pattern.size);
					// log(base) ( base^~patternLength) = max number
				varOffset=base.pow(~patternLength*varOffset);
// create a variation with the offset param
		pat=(pat+ ~revWeightFunc.value((varOffset+  NumericalExtensions.convertDigitsFloat(patternW  * (mask),2)).clip(0.0,base.pow(~patternLength)),pattern.size,base ).collect(_?0)  ).asInteger.clip(0,1);

})
})
});



	});
pat
}





)


//1.
//Build some arbitrary deterministic patterns from the generator
(
8.do({|i| ~machineDpatterns[(i*2)]=4.collect({~kernels.setKsSeq([81.rand,81.rand])[0]}).flat;
	~machineDpatterns[(i*2)+1]=4.collect({~kernels.setKsSeq([81.rand,81.rand])[1]}).flat;
}))




//store in a temporary array and make analysis.. (takes a long time)
// at output temp pat stores 16 banks of 18 sequences each of which the first 16 are actual patterns and the last two just fill up the data missing to cover a power of 2 data size for sysex part.

~tempPat[0].size

(

~tempPat=16.collect({|i|
	var mainIdx=i;
	var patterns=(~machineDpatterns).select({|item,i|i<17}).collect({
	|item|
//split the pattern in 2 for numeric limit



		var out=~testPeriod.value((item[0..~patternLength-1]),[[3,\full],[2,\alloperiodic],[5,\full],[7,\periodic],[4,\periodic]],(mainIdx)/32.0);

		//"original sequence".post;item[0..~patternLength-1].postln;


		if(~patternLength!=item.size, {out= out++ item[~patternLength..item.size-1];});
out;
});
	'.'.post;i.post;'.'.post;
	patterns++~machineDpatterns.select({|item,i|i>16});

})


)

~tempPat=16.collect({|i|var j=i; 18.collect({ |i| if(i%2==0,{~tempPat[j][i]},{(~tempPat[j][i]-~tempPat[j][i-1]).clip(0,1)})    })})
~tempPat[0]
8.collect({|i|  (~tempPat[0][(i*2)+1]-~tempPat[0][i*2]).clip(0,1)  })
lace
~tempPat.collect({|item|})

~tempPat[0].size



~tempPat.asString.interpret



(
var f;
f = File("D:/repos/sc_data/MDdata.dat".standardizePath,"w+");
f.write(~tempPat.asString);
//f.readAllString("D:/repos/sc_data/MDdata.dat").postln;

f.close;
)

~tempPat=  File.readAllString("D:/repos/sc_data/MDdata.dat")
~tempPat.
// 64 80...
//Send to MD
(
fork{
	16.do({|i|  ~sendPatterns.value(~dump,~tempPat[i],96+i); i.postln;3.wait; });
	"done".postln

}
)



Process.nowExecutingPath
//Patterns should be here
~machineDpatterns






~tempPat.postcs
















// ////////////////////////////////TESTS:





~revWeightFunc.value(24600576,64,17)
[ 0, 0, 0, 0, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 ]
[ 0, 0, 0, 0, 0, 0, 0, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, nil, nil, nil, nil, nil, nil, nil, nil, 0, 0, 0, 0, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, 0, 1, 0, 0, nil, nil, nil, nil, nil, nil, nil, nil, nil ]
string
NumericalExtensions.convertDigitsFloat([1,2,3],10)
NumericalExtensions.toBinaryArray(34.30430.floor,48)

~kernels.currentKsSeq.collect({item,i||wrapExtend(64)}).size


[(2..46),((0..46).nthPrime)].reduce('symmetricDifference').select({|item|item<47});

[1,2].difference([1,2,3])

x=[8.collect({|i|i.nthPrime}),[\full,\periodic]].allTuples
x.select({|item|item[]})

~dump[9]
~currentPattern
0.9.linexp(-1,1,1.0,0.1)
~tempPat.size

~tempPat[1][2]


~tempPat[0].sum==~machineDpatterns[0].sum
[[3,4],[1,2]].reduce('++')

~ksSeq
x=[]
~kernels.setBinarySeq([40,50])
x=  4.collect({~kernels.setBinarySeq([81.rand,81.rand])[0]}).flat
x=x.flat















NumericalExtensions.convertDigitsFloat([1,2,3,3],10)
2197790768.asBinaryDigits(48)

[0,0,0,0,1,1,0].find([1])
.finDur

~periodicityHisto.value(~machineDpatterns[8][0..~patternLength])

~weightFunc.value(~machineDpatterns[8][0..64],3).log2/64.0
(2.pow(64)).log2

~patternLength


(

)







[ 0, 0, 0, 1, 0, 0, 1, 0, 0, 0, 0, 1 ]
[ 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1 ]



~weightFunc.value([1,0,0,0,0,0,1,0,0,0],2);
3.asBinaryDigits(8)
17.asBinaryDigits(10)

~revWeightFunc.value(3,19,2);




~revWeightFunc.value(70,);
h=h.add(1)

1.asBoolean.xor(1.asBoolean)










