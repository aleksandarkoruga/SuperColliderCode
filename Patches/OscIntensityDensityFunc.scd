

(y={
	24.collect({|i| var d =i+1; (2*d).collect({|m| ((m+1)/d)}  ) }).flat.asFraction.collect({|item,i|item[0]/item[1] }).removeDuplicates.sort.asFraction

}
)

z=y.value


(
x=Routine(  {z.do({|item| "number :".post;item[0].post;"/".post;item[1].postln;0.3.wait}); })
)

x.play
z.find





(
// function to compute the nearest rhythmic intensity value at certain density
f={
	|density=0.5,intensity=0.5,size=128|
	var res,delta;
	var signDelta,counter=0;
	density=(density*size).asInteger;
	intensity=(2.pow(size))*intensity;


	// convert to binary number the intensity
	res=NumericalExtensions.toBinaryArray(intensity,size).floor.asInteger;
	// put lsb first -> re reverse sequence after substituting  zeroes or ones
	res=res.reverse;
	// using intensity function-> intensity value has same number of zeroes/ones as the rappresented sequence
	// if delta negative-> density of intensity func (res)> target density -> take away the amount of lsb otherwise add
	// by doing that the new intensity is calculated with a sequence that has the target density and nearest intensity
	delta=(density.postln-res.sum.postln);
	signDelta=delta.sign;
	delta=delta.abs;
	//signDelta becomes the target bit state to control
	if(signDelta<0,{signDelta=1},{signDelta=0});

	res=res.collect({ |item,idx| if(counter.postln<delta.postln,{if(item==signDelta,{counter=counter+1;1-signDelta},{item})},{item}) ; });
	res.postln;
	// re flip lsb
	res=res.reverse;
	res=NumericalExtensions.convertDigitsFloat(res,2);
	res.postln;
	~revWeightFunc.value(res,size,2);

}

)
f.value(1.0,0.4,16);







///

(
g={
	|msg|
	var density= msg[msg.size-9].clip(0.0,1.0),intensity=msg[((msg.size-8)..(msg.size-1))].clip(0.0,1.0);
	var seq;
	var dFunc={
	|density=0.5,intensity=0.5,size=128|
	var res,delta;
	var signDelta,counter=0;
	density=(density*size).asInteger;
	intensity=(2.pow(size))*intensity;


	// convert to binary number the intensity
	res=NumericalExtensions.toBinaryArray(intensity,size).floor.asInteger;
	// put lsb first -> re reverse sequence after substituting  zeroes or ones
	res=res.reverse;
	// using intensity function-> intensity value has same number of zeroes/ones as the rappresented sequence
	// if delta negative-> density of intensity func (res)> target density -> take away the amount of lsb otherwise add
	// by doing that the new intensity is calculated with a sequence that has the target density and nearest intensity


	delta=(density-res.sum);
	signDelta=delta.sign;
	delta=delta.abs;
		res.sum.postln;
		delta.postln;
	//signDelta becomes the target bit state to control
	if(signDelta<0.0,{signDelta=1},{signDelta=0});

		res=res.collect({ |item,idx|
			//"counter".postln;counter.postln;"rest".postln;
			if(counter<(delta+1),{if(item==signDelta,{counter=counter+1;1-signDelta},{item})},{item}) ; });

	// re flip lsb
	res=res.reverse;
	res=NumericalExtensions.convertDigitsFloat(res,2);
	~revWeightFunc.value(res,size,2).postln;

};
	//msg.postln;
	//intensity.postln;
	// get sequence
	seq= intensity.collect({|item|dFunc.value(density,item,52)} );

	//update buffer
	//~chopSeqBuf.sendCollection(seq.flat);

	//{|msg| 0.01.wait; ~chopSynth.set(\intensityBuf,~chopSeqBuf)}


}


)




g.value( ({0.1}!9) )

(2.4e+38)-(2.3999999999999999e+38)



	~revWeightFunc.value((NumericalExtensions.convertDigitsFloat((1!53++(0!0)).postln,2)).postln,53,2).postln;



(NumericalExtensions.convertDigitsFloat((1!60++(0!500)),2)).postln
NumericalExtensions.toBinaryArray(3.4028236692094434343434433e+40,180)


~revWeightFunc.value(1.7014118346047e+38,128,2);
3.4028236692094e+38-(3.4028236692094e+38-1.0e+4)