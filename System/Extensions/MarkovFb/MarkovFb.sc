MarkovFb
{
	var <matrix, <current, <size;

	*new { | size |
		^super.new.init(size.clip(2,256))
	}

	init { | size |
		this.generateMatrix(size)
	}
	generateMatrix{

		|inSize|
		var seq=Array.newClear(inSize);
		size=inSize;
		size.do({|i| seq.put(i,Array.fill(size,{rrand(0.0,1.0)}))});
		seq.do({|item,i|item; seq.put(i,item.normalizeSum(1.0)); }) ;
		current=rrand(0,size-1);
		matrix=seq;
	}


// /////////////////
	next{|chain|
	var res,column,prob;

	//result
	res= matrix.at(current).windex;

	column= matrix.at(current);
		prob=column.at(res);
		column.put(res,( prob+((1.0/(size*prob.clip(0.001,1.0)))*bilinrand(-1.0*prob,(1.0-prob))) ).abs  );

		column=column.normalizeSum(1.0);
	matrix.put( current,column );
	current=res;
	^current;
	}


// ////////////////////
	reset{|newSize|
		if(newSize.isNil,{newSize=size},{size=newSize.clip(2,256)});
		this.generateMatrix(newSize);
	}

}