
~synthParamBuf.plot
~synthParamBuf.loadCollection({1.0.rand+0.01}!1024)
~synthTrigBuf=Buffer.alloc(s,1024,1);
~synthTrigBuf.loadCollection(({0.5}!1024));
~synthTrigBuf.plot
0.1!16





(
SynthDef(\trigTest,{|trigBuf,modBuf,length,resetT|

	var sTrig=ListTrig2.kr(trigBuf,resetT,numframes:(length+1));
	var counter=PulseCount.kr(sTrig,resetT);
	var free=	FreeSelf.kr(Trig.kr(counter-length));

	var mods=WrapIndex.ar(modBuf,counter);
	counter.poll;





}).add

)


x=Synth(\trigTest,[\trigBuf,~synthTrigBuf,\modBuf,~synthParamBuf,\length,4,\resetT,0])
