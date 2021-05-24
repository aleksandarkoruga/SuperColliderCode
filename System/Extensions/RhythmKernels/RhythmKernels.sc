RhythmKernels
{

	classvar <ksList,<binaryList;
	var currentBinarySeq,currentKsSeq,currentBinarySteps,currentKsSteps;

	*initClass {
		ksList=this.prCalculateKS();
		binaryList=this.prCalculateBinary(16);
	}
	*new { |index=#[0,0]|
		^super.new.init(index)
	}

	init { |index=#[0,0]|
		this.setBinarySeq(index[0]);
		this.setKsSeq([index[1]]);

	}
	setBinarySeq
	{
		|index=0|

		currentBinarySeq=binaryList[index.wrap(0,binaryList.size-1)].deepCopy;
		currentBinarySteps=this.getSteps(currentBinarySeq);
		^currentBinarySeq;
	}
	setKsSeq
	{
		|index=#[0,0]|
		if(index.size==1,{index=[index[0],index[0]]});
		if(index.size>2,{index=index.copyRange(0,1)});

		currentKsSeq=[ksList[index[0]][0],ksList[index[1]][1]].deepCopy;
		currentKsSteps=[this.getSteps(currentKsSeq[0]),this.getSteps(currentKsSeq[1])].deepCopy;
		^currentKsSeq;

	}


	sizeBinaryColleciton
	{
		^binaryList.size;
	}
	sizeKSColleciton
	{
		^ksList.size;
	}



	// order the sequences for mean/std
	currentKsSeq
	{
		^currentKsSeq
	}
	currentBinarySeq
	{
		^currentBinarySeq
	}
	currentKsSteps
	{
		^currentKsSteps
	}
	currentBinarySteps
	{
		^currentBinarySteps
	}
	rotateBinary
	{
		|amount|
		currentBinarySeq=currentBinarySeq.rotate(amount);
		currentBinarySteps=this.getSteps(currentBinarySeq);
		^currentBinarySeq
	}

// //////////////////////////// //////////////////////////// //////////////////////////
// //////////////////////////// //////////////////////////// //////////////////////////
	*prCalculateBinary
	{
		|exponent=16|
		var t,a,b=[],c=[],func;

		t=List.fill(2.pow(exponent).asInt, { arg i; i  });
		t=t.removeAllSuchThat({ arg item, i; (item.isPowerOfTwo).not });

		//t=t.removeAllSuchThat({ arg item, i; (item.isPowerOfTwo).not });

		b=[];
		t.do({
			|item|
			var dig;

		dig=item.asDigits(2);
		dig=(0!(((t.last).asDigits(2).size)-dig.size))++dig;
		b=b.add(dig)
		});

		b.do({
			|item,i|
			c=c.add(item.sum)
		});

		b=b.at(c.order);

		b=b.removeAllSuchThat({ arg item, i; if(item.find([1,1]) ==nil,true,false)});

	//eliminate all rotations of the same pattern
	func={ |list|  var in,out;
	out=list;



	list.do({|item,i|
	var rotations=[];
	in=item;
			((in.size-1)).do({|i|  rotations=rotations.add(in.rotate(i+1))  });

	rotations.do({|item,i|
	var temp=item;
				out=out.removeAllSuchThat({ arg item, i; if((temp.find(item) ==nil),true,false)});
	});
		//out=out.add(list);
		});
		out

};

	^func.value(b);



	}




// //////////////////////////// //////////////////////////// //////////////////////////
// //////////////////////////// //////////////////////////// //////////////////////////

	*prCalculateKS
	{
	var res=[];
		81.do({
			arg idx=0;
			var
			k1=[ [0],[0,2],[0,2,-2] ]%16,
			k2=[ [8],[6,10],[6,8,10] ]%16,


			s1=[[4],[4,7] , [1,4,7]]%16,
			s2=[[12],[9,12],[9,12,15]]%16,
			outK=Array.fill(16,0),   //[\,\,\,\,\,\,\,\,\,\,\,\,\,\,\,\],
			outS=Array.fill(16,0),   //[\,\,\,\,\,\,\,\,\,\,\,\,\,\,\,\],

			resK=[],resS=[];

			var idn=idx.asDigits(3,4);

			resK;
			k2[idn[1]];
			resK=k1[idn[0]];
			resK=resK++k2[idn[1]];
			resS=s1[idn[2]];
			resS=resS++s2[idn[3]];
			resK.do({arg item,id; outK[item]=1 });
			resS.do({arg item,id; outS[item]=1 });
			res=res++	[[outK,outS]]

		});

		^res
	}


	getSteps{
|inList|
// get trig positions
var mulByIndex={
	|list|
	list=list.collect({|item,i|item*i});
			list
}
,stepsUntilNext
,listI=inList.deepCopy;//deep copy to not modify the source.

stepsUntilNext=mulByIndex.value(inList).add(inList.size).removeAllSuchThat({ arg item, i;  item!=0; }).differentiate;

	if(inList.first!=1,{
		stepsUntilNext.put(stepsUntilNext.size-1,stepsUntilNext.first+stepsUntilNext.last);
		stepsUntilNext.removeAt(0);});
	//inList.indicesOfEqual(1).size;


	if(inList.indicesOfEqual(1).size==stepsUntilNext.size,{
		stepsUntilNext.do({
	    |item,i|
		listI.put(inList.indicesOfEqual(1).at(i),item);
		});

	});
^listI
}


}


