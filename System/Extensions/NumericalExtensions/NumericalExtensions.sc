NumericalExtensions{



	*logN{
	|x,n|
	^(x.log2)/(n.log2);
	}
	*convertDigitsFloat
{
	|array,base|

	^(array.reverse.collect({|item,i| item*(base.pow(i))   }).sum)
}
	*toBinaryArray{
	|num,size|
	var arr=[];

	var	prDivTwo={|n,arr|if(n>1.0,{arr=arr.add(n%2); prDivTwo.value((n*0.5).floor,arr)},{arr=arr.add(n%2)});};

	arr=prDivTwo.value(num,arr);
	^((0!((size-arr.size).clip(0,inf)))++(arr.reverse))

}

}